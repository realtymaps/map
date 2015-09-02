_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require '../util.partiallyHandledError'
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require '../util.streams'
dbs = require '../../config/dbs'
config = require '../../config/config'
logger = require '../../config/logger'
jobQueue = require '../util.jobQueue'
validation = require '../util.validation'
memoize = require 'memoizee'
vm = require 'vm'
tables = require '../../config/tables'
sqlHelpers = require '../util.sql.helpers'
retsHelpers = require '../util.retsHelpers'
dataLoadHelpers = require './util.dataLoadHelpers'


_streamArrayToDbTable = (objects, tableName, fields, dataLoadHistory) ->
  # stream the results into a COPY FROM query; too bad we currently have to load the whole response into memory
  # first.  Eventually, we can rewrite the rets-promise client to use a streaming xml parser
  # like xml-stream or xml-object-stream, and then we can make this fully streaming (more performant)
  pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
  pgConnect = Promise.promisify(pgClient.connect, pgClient)
  pgQuery = Promise.promisify(pgClient.query, pgClient)
  pgConnect()
  .then () ->
    pgQuery('BEGIN')
  .then () ->
    startSql = tables.jobQueue.dataLoadHistory()
    .insert(dataLoadHistory)
    .toString()
    pgQuery(startSql)
  .then () ->
    pgQuery dataLoadHelpers.createRawTempTable(tableName, Object.keys(fields)).toString()
  .then () -> new Promise (resolve, reject) ->
    copyStart = "COPY #{tableName} (\"#{Object.keys(fields).join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8')"
    rawDataStream = pgClient.query(copyStream.from(copyStart))
    rawDataStream.on('finish', resolve)
    rawDataStream.on('error', reject)
    # stream from array to object serializer stream to COPY FROM
    from(objects)
    .pipe utilStreams.objectsToPgText(_.mapValues(fields, 'SystemName'))
    .pipe(rawDataStream)
  .then () ->
    finishSql = tables.jobQueue.dataLoadHistory()
    .where(raw_table_name: tableName)
    .update(raw_rows: objects.length)
    .toString()
    pgQuery(finishSql)
  .then () ->
    pgQuery('COMMIT')
  .finally () ->
    # always try to disconnect the db client when we're done, but don't crash if we disconnected prematurely
    try
      pgClient.end()
    catch err
      logger.warn "Error disconnecting raw db connection: #{err}"


_getValues = (list, target) ->
  if !target
    target = {}
  for item in list
    target[item.name] = item.value
  target


# this performs a diff of 2 sets of MLS data, returning only the changed/new/deleted fields as keys, with the value
# taken from row2.  Not all row fields are considered, only those that correspond most directly to the source MLS data,
# excluding those that are expected to be date-related derived values (notably DOM and CDOM)
_diff = (row1, row2, diffExcludeKeys=[]) ->
  fields1 = {}
  fields2 = {}

  # first, flatten the objects
  for groupName, groupList of row1.client_groups
    _getValues(groupList, fields1)
  for groupName, groupList of row1.realtor_groups
    _getValues(groupList, fields1)
  _.extend(fields1, row1.hidden_fields)
  _.extend(fields1, row1.ungrouped_fields)

  for groupName, groupList of row2.client_groups
    _getValues(groupList, fields2)
  for groupName, groupList of row2.realtor_groups
    _getValues(groupList, fields2)
  _.extend(fields2, row2.hidden_fields)
  _.extend(fields2, row2.ungrouped_fields)

  # then get changes from row1 to row2
  result = {}
  for fieldName, value1 of fields1
    if fieldName in diffExcludeKeys
      continue
    if !_.isEqual value1, fields2[fieldName]
      result[fieldName] = (fields2[fieldName] ? null)

  # then get fields missing from row1
  _.extend result, _.omit(fields2, Object.keys(fields1))


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options) ->
  # figure out when we last got updates from this table
  jobQueue.getLastTaskStartTime(subtask.task_name)
  .then (lastSuccess) ->
    now = new Date()
    if now.getTime() - lastSuccess.getTime() > 24*60*60*1000 || now.getDate() != lastSuccess.getDate()
      # if more than a day has elapsed or we've crossed a calendar date boundary, refresh everything and handle deletes
      logger.debug("Last successful run: #{lastSuccess} === performing full refresh")
      return new Date(0)
    else
      logger.debug("Last successful run: #{lastSuccess} --- performing incremental update")
      return lastSuccess
  .then (refreshThreshold) ->
    tables.config.mls()
    .where(id: subtask.task_name)
    .then (mlsInfo) ->
      mlsInfo = mlsInfo?[0]
      retsHelpers.getDataDump(mlsInfo, null, refreshThreshold)
      .then (results) ->
        if !results?.length
          # nothing to do, GTFO
          logger.info("No data updates for #{subtask.task_name}.")
          return
        # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
        # on whether this is a dump or an update)
        doDeletes = refreshThreshold.getTime() == 0
        recordCountsPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_recordChangeCounts", {markOtherRowsDeleted: doDeletes}, true)
        finalizePrepPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_finalizeDataPrep", null, true)
        activatePromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_activateNewData", {deleteUntouchedRows: doDeletes}, true)

        handleDataPromise = retsHelpers.getColumnList(mlsInfo, mlsInfo.listing_data.db, mlsInfo.listing_data.table)
        .then (fieldInfo) ->
          fields = _.indexBy(fieldInfo, 'LongName')
          rawTableName = dataLoadHelpers.getRawTableName subtask, 'listing'
          dataLoadHistory =
            data_source_id: options.dataSourceId
            data_source_type: 'mls'
            data_type: 'listing'
            batch_id: subtask.batch_id
            raw_table_name: rawTableName
          _streamArrayToDbTable(results, rawTableName, fields, dataLoadHistory)
          .then () ->
            return results.length
          .catch isUnhandled, (error) ->
            throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
        Promise.join handleDataPromise, recordCountsPromise, finalizePrepPromise, activatePromise, (numRawRows) ->
          return numRawRows
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to load RETS data for update")


updateRecord = (stats, diffExcludeKeys, usedKeys, rawData, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = _getValues(normalizedData.base || [])
  normalizedData.general.unshift(name: 'Address', value: base.address)
  normalizedData.general.unshift(name: 'Status', value: base.status_display)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(tables.propertyData.mls(), base.address)
    hide_listing: base.hide_listing ? false
    client_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      listing: normalizedData.listing || []
      building: normalizedData.building || []
      dimensions: normalizedData.dimensions || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    realtor_groups:
      contacts: normalizedData.contacts || []
      realtor: normalizedData.realtor || []
      sale: normalizedData.sale || []
    hidden_fields: _getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: null
  updateRow = _.extend base, stats, data
  # check for an existing row
  tables.propertyData.mls()
  .select('*')
  .where
    mls_uuid: updateRow.mls_uuid
    data_source_id: updateRow.data_source_id
  .then (result) ->
    if !result?.length
      # no existing row, just insert
      updateRow.inserted = stats.batch_id
      tables.propertyData.mls()
      .insert(updateRow)
    else
      # found an existing row, so need to update, but include change log
      result = result[0]
      updateRow.change_history = result.change_history ? []
      changes = _diff(updateRow, result, diffExcludeKeys)
      if !_.isEmpty changes
        updateRow.change_history.push changes
        updateRow.updated = stats.batch_id
      updateRow.change_history = sqlHelpers.safeJsonArray(tables.propertyData.mls(), updateRow.change_history)
      tables.propertyData.mls()
      .where
        mls_uuid: updateRow.mls_uuid
        data_source_id: updateRow.data_source_id
      .update(updateRow)


finalizeData = (subtask, id) ->
  listingsPromise = tables.propertyData.mls()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderBy('hide_listing')
  .orderByRaw('close_date DESC NULLS FIRST')
  parcelsPromise = tables.propertyData.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(rm_property_id: id)
  # TODO: we also need to select from the tax table for owner name info
  Promise.join listingsPromise, parcelsPromise, (listings=[], parcel=[]) ->
    if listings.length == 0
      # might happen if a listing is deleted during the day -- we'll catch it during the next full sync
      return
    listing = listings.shift()
    listing.data_source_type = 'mls'
    listing.active = false
    _.extend(listing, parcel[0])
    delete listing.deleted
    delete listing.hide_address
    delete listing.hide_listing
    delete listing.rm_inserted_time
    delete listing.rm_modified_time
    listing.prior_listings = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listings)
    listing.address = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.address)
    listing.change_history = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.change_history)
    tables.propertyData.combined()
    .insert(listing)

module.exports =
  loadUpdates: loadUpdates
  updateRecord: updateRecord
  finalizeData: finalizeData
