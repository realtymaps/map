Promise = require 'bluebird'

logger = require('../config/logger').spawn('task:digimaps:parcelHelpers:internals')
tables = require '../config/tables'
mlsHelpers = require './util.mlsHelpers'
countyHelpers = require './util.countyHelpers'
sqlHelpers = require '../utils/util.sql.helpers'


column = 'feature'

diffExcludeKeys = [
  'rm_inserted_time'
  'rm_modified_time'
  'geom_polys_raw'
  'geom_point_raw'
  'change_history'
  'deleted'
  'inserted'
  'updated'
  'batch_id'
  'rm_raw_id'
]

diffBooleanKeys = [
  'geom_polys_json'
  'geom_point_json'
]

finalizeParcelEntry = ({entries, subtask}) ->
  entry = entries.shift()
  entry.active = false
  delete entry.deleted
  delete entry.rm_inserted_time
  delete entry.rm_modified_time
  entry.prior_entries = sqlHelpers.safeJsonArray(entries)
  entry.change_history = sqlHelpers.safeJsonArray(entry.change_history)
  entry.update_source = subtask.task_name
  entry


finalizeNewParcel = ({parcels, id, subtask, transaction}) ->
  parcel = finalizeParcelEntry({entries: parcels, subtask})

  tables.property.parcel(transaction: transaction)
  .where
    rm_property_id: id
    data_source_id: subtask.task_name
    active: false
  .delete()
  .then () ->
    tables.property.parcel(transaction: transaction)
    .insert(parcel)
  .then () ->
    return parcel


finalizeUpdateListing = ({id, subtask, transaction, finalizedParcel}) ->
  tables.property.combined(transaction: transaction)
  .where
    rm_property_id: id
    active: true
  .then (rows) ->
    promises = for r in rows
      do (r) ->
        #figure out data_source_id and type
        #execute finalize for that specific MLS (subtask)
        if r.data_source_type == 'mls'
          logger.debug "mlsHelpers.finalizeData"
          mlsHelpers.finalizeData {
            subtask
            id
            data_source_id: r.data_source_id
            finalizedParcel
            transaction
            delay: 0
          }
        else
          logger.debug "countyHelpers.finalizeData"
          #delay is zero since higher up the change we have already been delayed
          countyHelpers.finalizeData {
            subtask
            id
            data_source_id: r.data_source_id
            transaction
            delay: 0
            finalizedParcel
            forceFinalize: true
          }
    Promise.all promises



module.exports = {
  finalizeNewParcel
  finalizeParcelEntry
  finalizeUpdateListing
  column
  diffExcludeKeys
  diffBooleanKeys
}
