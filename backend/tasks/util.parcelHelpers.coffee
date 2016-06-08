Promise = require 'bluebird'
_ = require 'lodash'
util = require 'util'

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
transforms = require '../utils/transforms/transform.parcel'


saveToNormalDb = ({subtask, rows, fipsCode, delay}) -> Promise.try ->
  successes = []
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
          dataType: 'normParcel'
          updateRow: row
          delay
          flattenRows: false
          diffExcludeKeys: internals.diffExcludeKeys
          diffBooleanKeys: internals.diffBooleanKeys
        }
        .then (rm_property_id) ->
          successes.push(rm_property_id)
      #removed for performance
      #.then () ->
      #  tables.temp(subid: rawSubid)
      #  .where({rm_raw_id})
      #  .update(rm_valid: true, rm_error_msg: null)
      .catch analyzeValue.isKnexError, (err) ->
        jsonData = util.inspect(row, depth: null)
        logger.warn "#{analyzeValue.getSimpleMessage(err)}\nData: #{jsonData}"
        throw new HardFail(err.message)
      .catch validation.DataValidationError, (err) ->
        tables.temp(subid: rawSubid)
        .where({rm_raw_id})
        .update(rm_valid: false, rm_error_msg: err.toString())
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'problem saving normalized data')
  .then () ->
    if successes.length == 0
      logger.debug("No successful data updates from #{subtask.task_name} normalize subtask: "+JSON.stringify(i: subtask.data.i, of: subtask.data.of, rawTableSuffix: subtask.data.rawTableSuffix))
      return
    manualData =
      cause: 'parcel'
      i: subtask.data.i
      of: subtask.data.of
      rawTableSuffix: subtask.data.rawTableSuffix
      count: successes.length
      values: successes
      normalSubid: fipsCode  # required for countyHelpers.finalizeData
      deletedParcel: false
    jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "finalizeData", manualData})


finalizeData = (subtask, id, delay) -> Promise.try () ->
  delay ?= 100
  ###
  - MOVE / UPSERT entire normalized.parcel table to main.parcel
  - UPDATE LISTINGS / data_combined geometries
  ###
  Promise.delay(delay)
  .then () ->
    if subtask.data.deletedParcel
      dbs.get('main').transaction (transaction) ->
        internals.finalizeUpdateListing {id, subtask, transaction, finalizedParcel: false}
    else
      tables.property.normParcel()
      .select('*')
      .where(rm_property_id: id)
      .whereNull('deleted')
      .orderBy('rm_property_id')
      .orderBy('deleted')
      .then (parcels) ->
        if parcels.length == 0
          throw new HardFail("No parcel entries found for: #{id}")

        dbs.get('main').transaction (transaction) ->
          internals.finalizeNewParcel {parcels, id, subtask, transaction}
          .then (finalizedParcel) ->
            transforms.execFinalizeParcelAsDataCombined(finalizedParcel)
          .then (finalizedParcel) ->
            internals.finalizeUpdateListing {id, subtask, transaction, finalizedParcel}

  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, 'failed to finalizeData')
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))


activateNewData = (subtask) -> Promise.try () ->
  logger.debug subtask

  dbs.get('main').transaction (transaction) ->

    activateParcels = dataLoadHelpers.activateNewData(subtask, {
      propertyPropName: 'parcel',
      deletesPropName: 'parcel'
      transaction}
    )
    activateDataCombined = dataLoadHelpers.activateNewData(subtask, transaction: transaction)
    Promise.join activateParcels, activateDataCombined, () ->  # noop


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

getParcelsPromise = ({rm_property_id, active, transaction}) ->
  active ?= true

  tables.property.parcel(transaction: transaction)
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where({rm_property_id, active})


module.exports = {
  saveToNormalDb
  finalizeData
  finalizeParcelEntry: internals.finalizeParcelEntry
  activateNewData
  handleOveralNormalizeError
  column: internals.column
  getParcelsPromise
}
