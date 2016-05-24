Promise = require 'bluebird'
_ = require 'lodash'

logger = require('../config/logger').spawn('task:digimaps:parcelHelpers')
parcelUtils = require '../utils/util.parcel'
tables = require '../config/tables'
dbs = require '../config/dbs'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
validation = require '../utils/util.validation'
internals = require './util.parcelHelpers.internals'


saveToNormalDb = ({subtask, rows, fipsCode, delay}) -> Promise.try ->
  tableName = 'parcel'
  rawSubid = dataLoadHelpers.buildUniqueSubtaskName(subtask)
  delay ?= 100

  jobQueue.getLastTaskStartTime(subtask.task_name, false)
  .then (startTime) ->

    normalPayloadsPromise = parcelUtils.normalize {
      batch_id: subtask.batch_id
      data_source_id: subtask.task_name
      rows
      fipsCode
      startTime
    }

    logger.debug "got #{normalPayloadsPromise.length} normalized rows"

    tablesPropName = 'norm'+tableName.toInitCaps()

    #these promises must happen in order since we might have multiple props of the same rm_property_id
    # due to appartments; and or geom_poly_json or geom_point_json for the same prop (since they come in sep payloads)
    #THIS FIXES insert collisions when they should be updates
    #TODO: Bluebird 3.X use mapSeries
    Promise.each normalPayloadsPromise, (payload) ->
      # logger.debug payload

      #NOTE: rm_raw_id is always defined which is why it is destructured here
      # this way we do not need to check for stats or row defined.
      {row, stats, error, rm_raw_id} = payload

      Promise.try () ->
        if error
          throw error

        dataLoadHelpers.updateRecord {
          stats
          dataType: tablesPropName
          updateRow: row
          delay
          getRowChanges: internals.getRowChanges
        }
      #removed for performance
      #.then () ->
      #  tables.temp(subid: rawSubid)
      #  .where({rm_raw_id})
      #  .update(rm_valid: true, rm_error_msg: null)
      .catch analyzeValue.isKnexError, (err) ->
        jsonData = JSON.stringify(row,null,2)
        logger.warn "#{analyzeValue.getSimpleMessage(err)}\nData: #{jsonData}"
        throw HardFail err.message
      .catch validation.DataValidationError, (err) ->
        tables.temp(subid: rawSubid)
        .where({rm_raw_id})
        .update(rm_valid: false, rm_error_msg: err.toString())
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'problem saving normalized data')


finalizeData = (subtask, id, delay) -> Promise.try () ->
  delay ?= 100
  ###
  - MOVE / UPSERT entire normalized.parcel table to main.parcel
  - UPDATE LISTINGS / data_combined geometries
  ###
  logger.debug () -> "<#{id}> parcelHelpers.finalizeData START"
  Promise.delay delay
  .then () ->
    tables.property.normParcel()
    .select('*')
    .where(rm_property_id: id)
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .then (parcels) ->
      logger.debug () -> "<#{id}> parcelHelpers.finalizeData parcels.length: #{parcels.length}"
      if parcels.length == 0
        # might happen if a singleton listing is deleted during the day
        return tables.deletes.parcel()
        .insert
          rm_property_id: id
          data_source_id: subtask.task_name
          batch_id: subtask.batch_id

      dbs.get('main').transaction (transaction) ->
        logger.debug () -> "<#{id}> parcelHelpers.finalizeData transaction start"
        internals.finalizeNewParcel {parcels, id, subtask, transaction}
        .then () ->
          internals.finalizeUpdateListing {id, subtask, transaction}


activateNewData = (subtask) ->
  logger.debug subtask

  dataLoadHelpers.activateNewData subtask, {
    propertyPropName: 'parcel',
    deletesPropName: 'parcel'
  }

handleOveralNormalizeError = ({error, dataLoadHistory, numRawRows, fileName}) ->
  errorLogger = logger.spawn('handleOveralNormalizeError')

  errorLogger.debug "handling error"
  errorLogger.debug error
  errorLogger.debug fileName

  updateEntity =
    rm_valid: false
    rm_error_msg: fileName + " : " + error.message
    raw_rows: 0

  tables.jobQueue.dataLoadHistory()
  .where dataLoadHistory
  .then (results) ->
    if results?.length
      tables.jobQueue.dataLoadHistory()
      .where dataLoadHistory
      .update updateEntity
    else
      tables.jobQueue.dataLoadHistory()
      .insert _.extend {}, dataLoadHistory, updateEntity
  .then () ->
    if numRawRows?
      numRawRows

getRecordChangeCountsData = (fipsCode) ->
  {
    deletes: dataLoadHelpers.DELETE.UNTOUCHED
    dataType: "normParcel"
    rawDataType: "parcel"
    rawTableSuffix: fipsCode
    subset:
      fips_code: fipsCode
  }

getFinalizeSubtaskData = ({subtask, ids, fipsCode, numRowsToPageFinalize}) ->
  {
    subtask
    totalOrList: ids
    maxPage: numRowsToPageFinalize
    laterSubtaskName: "finalizeData"
    mergeData:
      normalSubid: fipsCode #required for countyHelpers.finalizeData
  }

getParcelsPromise = ({rm_property_id, active}) ->
  active ?= true

  tables.property.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where({rm_property_id, active})


module.exports = {
  saveToNormalDb
  finalizeData
  finalizeParcelEntry: internals.finalizeParcelEntry
  activateNewData
  handleOveralNormalizeError
  column: internals.column
  getRecordChangeCountsData
  getFinalizeSubtaskData
  getParcelsPromise
}
