Promise = require 'bluebird'

logger = require('../config/logger').spawn('(tasks) util.parcelHelpers')
parcelUtils = require '../utils/util.parcel'
tables = require '../config/tables'
dbs = require '../config/dbs'
dataLoadHelpers = require './util.dataLoadHelpers'
mlsHelpers = require './util.mlsHelpers'
sqlHelpers = require '../utils/util.sql.helpers'

DELAY_MILLISECONDS = 100


saveToNormalDb = ({subtask, rows, fipsCode}) -> Promise.try ->
  database = 'normalized'
  tableName = 'parcel'

  normalRows = parcelUtils.normalize {
    batch_id: subtask.batch_id
    data_source_id: subtask.task_name
    rows
    fipsCode
  }

  tablesPropName = 'norm'+tableName.toInitCaps()

  promises = for row in normalRows
    do (row) ->
      tables.property[tablesPropName]()
      .where rm_property_id: row.rm_property_id
      .count()
      .then ([{count}]) ->
        count = parseInt count
        p = if count == 0
          tables.property[tablesPropName]().raw parcelUtils.insertParcelStr {row, tableName, database}
          .then () ->
        else
          tables.property[tablesPropName]().raw parcelUtils.updateParcelStr {row, tableName, database}
          .then () ->

        p.catch () ->

  Promise.all promises
  .catch (error) ->
    logger.maybeInvalidError {error}

_finalizeUpdateListing = ({id, subtask}) ->
  #should not need owner promotion logic since it should have already been done
  Promise.delay(DELAY_MILLISECONDS)  #throttle for heroku's sake
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

_finalizeNewParcel = ({parcels, id, subtask}) ->
  parcel = finalizeParcelEntry(parcels)

  Promise.delay(DELAY_MILLISECONDS)  #throttle for heroku's sake
  .then () ->
    dbs.get('main').transaction (transaction) ->
      tables.property.parcel(transaction: transaction)
      .where
        rm_property_id: id
        data_source_id: subtask.task_name
        active: false
      .delete()
      .then () ->
        tables.property.parcel(transaction: transaction)
        .insert(parcel)

finalizeData = (subtask, id) -> Promise.try () ->
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

    finalizeListingPromise = _finalizeUpdateListing({id, subtask})
    finalizeParcelPromise = _finalizeNewParcel({parcels, id, subtask})

    Promise.all [finalizeListingPromise, finalizeParcelPromise]


activateNewData = (subtask) ->
  dataLoadHelpers.activateNewData subtask, {
    propertyPropName: 'parcel',
    deletesPropName: 'parcel'
  }

module.exports = {
  saveToNormalDb
  finalizeData
  finalizeParcelEntry
  activateNewData
}
