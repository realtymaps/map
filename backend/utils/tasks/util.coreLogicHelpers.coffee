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
tables = require '../../config/tables'
sqlHelpers = require '../util.sql.helpers'
retsHelpers = require '../util.retsHelpers'
dataLoadHelpers = require './util.dataLoadHelpers'
PromiseFtp = require '../util.promiseFtp'
encryptor = require '../../config/encryptor'
unzip = require 'unzip'
split = require 'split'
combinedStream = require('combined-stream2')


_streamZipToDbTable = (zipFileStream, tableName, dataLoadHistory) ->
  # stream the contents of the file into a COPY FROM query
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
  .then () -> new Promise (resolve, reject) ->
    gotFile = false
    zipFileStream
    .pipe(unzip.Parse())
    .on 'entry', (entry) ->
      if entry.type == 'Directory'
        logger.warn "Found an unexpected directory inside zip: #{entry.path}"
        entry.autodrain()
        return
      if gotFile
        logger.warn "found an unexpected additional file inside zip: #{entry.path}"
        entry.autodrain()
        return
      gotFile = true
      splitter = split()
      lineSplits = entry
      .pipe(splitter)
      lineSplits.once 'data', (headerLine) ->
        # immediately unpipe, so the line splitter doesn't pull more data
        entry.unpipe(splitter)
        # corelogic gives us header names in all caps, with spaces and other punctuation in the names, delimited by tabs
        fields = headerLine.toLowerCase().replace(/[^a-z0-9\t]+/g, '_').split('\t')
        pgQuery dataLoadHelpers.createRawTempTable(tableName, fields).toString()
        .then () ->
          copyStart = "COPY #{tableName} (\"#{fields.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8', NULL '')"
          rawDataStream = pgClient.query(copyStream.from(copyStart))
          rawDataStream.on('finish', resolve)
          rawDataStream.on('error', reject)
          # stream the rest of the unzipped file directly to COPY FROM, with an appended termination buffer
          copyInto = combinedStream.create()
          copyInto.append(entry)
          copyInto.append(new Buffer('\\.\n'))
          copyInto.pipe(rawDataStream)
  .then () ->
    finishSql = tables.jobQueue.dataLoadHistory()
    .where
      raw_table_name: tableName
    .update
      raw_rows: objects.length
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


# loads all records from a ftp-dropped zip file
loadRawData = (subtask, options) ->
  rawTableName = dataLoadHelpers.getRawTableName subtask, options.rawTableSuffix
  ftp = new PromiseFtp()
  ftp.connect
    host: subtask.task_data.host
    user: subtask.task_data.user
    password: encryptor.decrypt(subtask.task_data.password)
  .then () ->
    ftp.get(subtask.data.path)
  .then (zipFileStream) ->
    dataLoadHistory =
      data_source_id: options.dataSourceId
      data_source_type: 'county'
      data_type: subtask.data.type
      batch_id: subtask.batch_id
      raw_table_name: rawTableName

    _streamZipToDbTable(zipFileStream, rawTableName, dataLoadHistory)
    .then (rowsInserted) ->
      return rowsInserted
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
  Promise.join handleDataPromise, recordCountsPromise, finalizePrepPromise, activatePromise, (numRawRows) ->
    return numRawRows
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to load RETS data for update")


# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) -> Promise.try () ->
  rawTableName = dataLoadHelpers.getRawTableName subtask, options.rawTableSuffix
  # get rows for this subtask
  rowsPromise = dbs.properties.knex(rawTableName)
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
  # get validations
  validationPromise = dataLoadHelpers.getValidations(options.dataSourceId)
  # get start time for "last updated" stamp
  startTimePromise = jobQueue.getLastTaskStartTime(subtask.task_name, false)
  Promise.join rowsPromise, validationPromise, startTimePromise, (rows, validationMap, startTime) ->
    # calculate the keys that are grouped for later
    usedKeys = ['rm_raw_id', 'rm_valid', 'rm_error_msg'] # exclude these internal-only fields from showing up as "unused"
    diffExcludeKeys = []
    for groupName, validationList of validationMap
      for validationDefinition in validationList
        # generally, don't count the 'base' fields as being used, but we do for 'address' and 'status', as the source
        # fields for those don't have to be explicitly reused
        if validationDefinition.list != 'base' || validationDefinition.output == 'address' || validationDefinition.output == 'status_display'
          usedKeys = usedKeys.concat(dataLoadHelpers.getUsedInputFields(validationDefinition))
        else if validationDefinition.output == 'days_on_market'
          # explicitly exclude these keys from diff, because they are derived values based on date
          diffExcludeKeys = dataLoadHelpers.getUsedInputFields(validationDefinition)
    promises = for row in rows
      do (row) ->
        stats =
          data_source_id: options.dataSourceId
          batch_id: subtask.batch_id
          rm_raw_id: row.rm_raw_id
          up_to_date: startTime
        Promise.props(_.mapValues(validationMap, validation.validateAndTransform.bind(null, row)))
        .then _updateRecord.bind(null, stats, diffExcludeKeys, usedKeys, row)
        .then () ->
          dbs.properties.knex(rawTableName)
          .where(rm_raw_id: row.rm_raw_id)
          .update(rm_valid: true)
        .catch validation.DataValidationError, (err) ->
          dbs.properties.knex(rawTableName)
          .where(rm_raw_id: row.rm_raw_id)
          .update(rm_valid: false, rm_error_msg: err.toString())
    Promise.all promises


_updateRecord = (stats, diffExcludeKeys, usedKeys, rawData, normalizedData) -> Promise.try () ->
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
  normalizeData: normalizeData
  finalizeData: finalizeData
