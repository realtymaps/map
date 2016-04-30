Promise = require 'bluebird'
_ = require 'lodash'
diff = require('deep-diff').diff

logger = require('../config/logger').spawn('task:digimaps:parcelHelpers')
parcelUtils = require '../utils/util.parcel'
tables = require '../config/tables'
dbs = require '../config/dbs'
dataLoadHelpers = require './util.dataLoadHelpers'
mlsHelpers = require './util.mlsHelpers'
sqlHelpers = require '../utils/util.sql.helpers'
jobQueue = require '../services/service.jobQueue'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'

column = 'feature'

diffExcludeKeys = [
  'rm_inserted_time'
  'rm_modified_time'
  'geom_polys_raw'
  'geom_point_raw'
  'change_history'
  # 'deleted'
  # 'inserted'
  # 'updated'
]

getRowChanges = (row1, row2) ->
  diff(_.omit(row1, diffExcludeKeys), _.omit(row2, diffExcludeKeys))


saveToNormalDb = ({subtask, rows, fipsCode, delay}) -> Promise.try ->
  tableName = 'parcel'
  rawSubid = dataLoadHelpers.buildUniqueSubtaskName(subtask)
  delay ?= 100

  jobQueue.getLastTaskStartTime(subtask.task_name, false)
  .then (startTime) ->

    normalPayloads = parcelUtils.normalize {
      batch_id: subtask.batch_id
      data_source_id: subtask.task_name
      rows
      fipsCode
      startTime
    }

    logger.debug "got #{normalPayloads.length} normalized rows"

    tablesPropName = 'norm'+tableName.toInitCaps()


    #these promises must happen in order since we might have multiple props of the same rm_property_id
    # due to appartments; and or geom_poly_json or geom_point_json for the same prop (since they come in sep payloads)
    #THIS FIXES insert collisions when they should be updates
    #TODO: Bluebird 3.X use mapSeries
    Promise.each normalPayloads, (payload) ->
      # logger.debug payload

      {row, stats, error, rm_raw_id} =  payload

      Promise.try () ->
        if error
          throw error

        dataLoadHelpers.updateRecord {
          stats
          dataType: tablesPropName
          updateRow: row
          delay
          getRowChanges
        }
      #removed for performance
      #.then () ->
      #  tables.temp(subid: rawSubid)
      #  .where(rm_raw_id: rm_raw_id)
      #  .update(rm_valid: true, rm_error_msg: null)
      .catch analyzeValue.isKnexError, (err) ->
        jsonData = JSON.stringify(row,null,2)
        logger.warn "#{analyzeValue.getSimpleMessage(err)}\nData: #{jsonData}"
        tables.temp(subid: rawSubid)
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: false, rm_error_msg: "#{analyzeValue.getSimpleDetails(err)}\nData: #{jsonData}")
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'problem saving normalized data')
    .catch (error) ->
      throw new SoftFail(analyzeValue.getSimpleMessage(error))

_finalizeUpdateListing = ({id, subtask, delay}) ->
  delay ?= 100
  #should not need owner promotion logic since it should have already been done
  Promise.delay(delay)  #throttle for heroku's sake
  .then () ->
    dbs.get('main').transaction (transaction) ->
      tables.property.combined(transaction: transaction)
      .where
        rm_property_id: id
        active: true
      .then (rows) ->
        promises = for r in rows
          do (r) ->
            #figure out data_source_id and type
            #execute finalize for that specific MLS (subtask)
            mlsHelpers.finalizeData({subtask, id, data_source_id: r.data_source_id})

        Promise.all promises

finalizeParcelEntry = (entries) ->
  entry = entries.shift()
  entry.active = false
  delete entry.deleted
  delete entry.rm_inserted_time
  delete entry.rm_modified_time
  entry.prior_entries = sqlHelpers.safeJsonArray(entries)
  entry.change_history = sqlHelpers.safeJsonArray(entry.change_history)
  entry.update_source = entry.data_source_id
  entry

_finalizeNewParcel = ({parcels, id, subtask, delay}) ->
  delay ?= 100
  parcel = finalizeParcelEntry(parcels)

  Promise.delay(delay)  #throttle for heroku's sake
  .then () ->
    dbs.get('main').transaction (transaction) ->
      tables.property.parcel(transaction: transaction)
      .where
        rm_property_id: id
        data_source_id: subtask.task_name
        # active: false , #eventually this should be false, but for now this avoids collisions and updates legacy
      .delete()
      .then () ->
        tables.property.parcel(transaction: transaction)
        .insert(parcel)

finalizeData = (subtask, id, delay) -> Promise.try () ->
  ###
  - MOVE / UPSERT entire normalized.parcel table to main.parcel
  - UPDATE LISTINGS / data_combined geometries
  ###
  tables.property.normParcel()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .then (parcels) ->
    if parcels.length == 0
      # might happen if a singleton listing is deleted during the day
      return tables.deletes.parcel()
      .insert
        rm_property_id: id
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id

    finalizeListingPromise = _finalizeUpdateListing({id, subtask, delay})
    finalizeParcelPromise = _finalizeNewParcel({parcels, id, subtask, delay})

    Promise.all [finalizeListingPromise, finalizeParcelPromise]


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


module.exports = {
  saveToNormalDb
  finalizeData
  finalizeParcelEntry
  activateNewData
  handleOveralNormalizeError
  column
}
