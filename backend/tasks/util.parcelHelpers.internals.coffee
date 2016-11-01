Promise = require 'bluebird'

logger = require('../config/logger').spawn('task:digimaps:parcelHelpers:internals')
finalLogger = logger.spawn('final')
tables = require '../config/tables'
mlsListingInternals = require './task.default.mls.listing.internals'
countyHelpers = require './util.countyHelpers'
sqlHelpers = require '../utils/util.sql.helpers'

column = 'feature'

diffExcludeKeys = [
  'rm_inserted_time'
  'rm_modified_time'
  'geometry_raw'
  'geometry_center_raw'
  'change_history'
  'deleted'
  'inserted'
  'updated'
  'batch_id'
  'rm_raw_id'
]

diffBooleanKeys = [
  'geometry'
  'geometry_center'
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

  if !parcel.street_address_num?
    delete parcel.stree_address_num

  if !parcel.street_unit_num?
    delete parcel.street_unit_num

  tables.finalized.parcel(transaction: transaction)
  .where
    rm_property_id: id
    data_source_id: subtask.task_name
    active: false
  .delete()
  .then () ->
    finalLogger.debug -> parcel
    tables.finalized.parcel(transaction: transaction)
    .insert(parcel)
  .then () ->
    return parcel


finalizeUpdateListing = ({id, subtask, transaction, finalizedParcel}) ->
  tables.finalized.combined(transaction: transaction)
  .where
    rm_property_id: id
    active: true
  .then (rows) ->
    promises = for r in rows
      do (r) ->
        #figure out data_source_id and type
        #execute finalize for that specific MLS (subtask)
        if r.data_source_type == 'mls'
          finalLogger.debug "mlsListingInternals.finalizeData"
          mlsListingInternals.finalizeData {
            subtask
            id
            data_source_id: r.data_source_id
            finalizedParcel
            transaction
            delay: 0
          }
        else
          finalLogger.debug "countyHelpers.finalizeData"
          #delay is zero since higher up the chain we have already been delayed
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
