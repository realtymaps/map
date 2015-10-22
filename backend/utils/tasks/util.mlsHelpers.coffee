_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../errors/util.error.partiallyHandledError'
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require '../util.streams'
dbs = require '../../config/dbs'
config = require '../../config/config'
logger = require '../../config/logger'
jobQueue = require '../util.jobQueue'
validation = require '../util.validation'
vm = require 'vm'
tables = require '../../config/tables'
sqlHelpers = require '../util.sql.helpers'
retsHelpers = require '../util.retsHelpers'
dataLoadHelpers = require './util.dataLoadHelpers'
rets = require 'rets-client'
{SoftFail} = require '../errors/util.error.jobQueue'
through2 = require 'through2'


_retsToDbStreamer = (retsStream) ->
  # stream the results into a COPY FROM query
  (tableName, promiseQuery, streamQuery) -> new Promise (resolve, reject) ->
    delimiter = null
    dbStream = null
    started = false
    dbStreamer = through2.obj (event, encoding, callback) ->
      try
        if !started
          started = true
        switch event.type
          when 'data'
            dbStream.write(utilStreams.pgStreamEscape(event.payload))
            dbStream.write('\n')
            callback()
          when 'delimiter'
            delimiter = event.payload
            callback()
          when 'columns'
            promiseQuery(dbs.get('raw_temp').schema.dropTableIfExists(tableName))
            .then () ->
              tables.jobQueue.dataLoadHistory()
              .where(raw_table_name: tableName)
              .delete()
            .then () ->
              promiseQuery(dataLoadHelpers.createRawTempTable(tableName, event.payload))
            .then () ->
              copyStart = "COPY \"#{tableName}\" (\"#{event.payload.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8', NULL '', DELIMITER '#{delimiter}')"
              dbStream = streamQuery(copyStream.from(copyStart))
              callback()
          when 'done'
            resolve(event.payload)
            retsStream.unpipe(dbStreamer)
            dbStream.write('\\.\n')
            dbStream.end()
            dbStreamer.end()
            callback()
          when 'error'
            reject(event.payload)
            retsStream.unpipe(dbStreamer)
            dbStream.write('\\.\n')
            dbStream.end()
            dbStreamer.end()
            callback()
          else
            callback()
      catch err
        reject(event.payload)
        retsStream.unpipe(dbStreamer)
        dbStream.write('\\.\n')
        dbStream.end()
        dbStreamer.end()
        callback()
        
    retsStream.pipe(dbStreamer)


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options) ->
  # figure out when we last got updates from this table
  jobQueue.getLastTaskStartTime(subtask.task_name)
  .then (lastSuccess) ->
    now = new Date()
    if now.getTime() - lastSuccess.getTime() > 24*60*60*1000 || now.getDate() != lastSuccess.getDate()
      # if more than a day has elapsed or we've crossed a calendar date boundary, refresh everything and handle deletes
      logger.debug("Last successful run: #{lastSuccess} === performing full refresh for #{subtask.task_name}")
      return new Date(0)
    else
      logger.debug("Last successful run: #{lastSuccess} --- performing incremental update for #{subtask.task_name}")
      return lastSuccess
  .then (refreshThreshold) ->
    tables.config.mls()
    .where(id: subtask.task_name)
    .then (mlsInfo) ->
      mlsInfo = mlsInfo?[0]
      retsHelpers.getDataStream(mlsInfo, null, refreshThreshold)
      .catch isCausedBy(rets.RetsReplyError), (error) ->
        if error.replyTag in ["MISC_LOGIN_ERROR", "DUPLICATE_LOGIN_PROHIBITED", "SERVER_TEMPORARILY_DISABLED"]
          throw SoftFail(error, "Transient RETS error; try again later")
        throw error
    .then (retsStream) ->
      rawTableName = dataLoadHelpers.buildUniqueSubtaskName(subtask)
      dataLoadHistory =
        data_source_id: options.dataSourceId
        data_source_type: 'mls'
        data_type: 'listing'
        batch_id: subtask.batch_id
        raw_table_name: rawTableName
      dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, _retsToDbStreamer(retsStream))
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
    .then (numRawRows) ->
      # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
      # on whether this is a dump or an update)
      deletes = if refreshThreshold.getTime() == 0 then dataLoadHelpers.DELETE.UNTOUCHED else dataLoadHelpers.DELETE.NONE
      recordCountsPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_recordChangeCounts", {deletes: deletes, dataType: 'listing'}, true)
      finalizePrepPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_finalizeDataPrep", null, true)
      activatePromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_activateNewData", {deletes: deletes}, true)
      Promise.join recordCountsPromise, finalizePrepPromise, activatePromise, () ->
        numRawRows
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, 'failed to load RETS data for update')


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  normalizedData.general.unshift(name: 'Address', value: base.address)
  normalizedData.general.unshift(name: 'Status', value: base.status_display)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(base.address)
    hide_listing: base.hide_listing ? false
    shared_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      listing: normalizedData.listing || []
      building: normalizedData.building || []
      dimensions: normalizedData.dimensions || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    subscriber_groups:
      contacts: normalizedData.contacts || []
      realtor: normalizedData.realtor || []
      sale: normalizedData.sale || []
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: null
  _.extend base, stats, data


finalizeData = (subtask, id) ->
  listingsPromise = tables.property.listing()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderBy('hide_listing')
  .orderByRaw('close_date DESC NULLS FIRST')
  parcelsPromise = tables.property.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(rm_property_id: id)
  # TODO: we also need to select from the tax table for owner name info
  Promise.join listingsPromise, parcelsPromise, (listings=[], parcel=[]) ->
    if listings.length == 0
      # might happen if a singleton listing is deleted during the day
      return tables.property.deletes()
      .insert
        rm_property_id: id
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id
    listing = dataLoadHelpers.finalizeEntry(listings)
    listing.data_source_type = 'mls'
    _.extend(listing, parcel[0])
    tables.property.combined()
    .insert(listing)

module.exports =
  loadUpdates: loadUpdates
  buildRecord: buildRecord
  finalizeData: finalizeData
