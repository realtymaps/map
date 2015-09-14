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
unzip = require 'unzip2'
split = require 'split'
fs = require 'fs'
path = require 'path'
through = require 'through2'
rimraf = require 'rimraf'


_streamFileToDbTable = (filePath, tableName, dataLoadHistory, debug) ->
  # stream the contents of the file into a COPY FROM query
  count = 0
  pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
  pgQuery = Promise.promisify(pgClient.query, pgClient)
  pgConnect = Promise.promisify(pgClient.connect, pgClient)
  pgConnect()
  .then () ->
    pgQuery('BEGIN')
  .then () ->
    startSql = tables.jobQueue.dataLoadHistory()
    .insert(dataLoadHistory)
    .toString()
    pgQuery(startSql)
  .then () -> new Promise (resolve, reject) ->
    rejected = false
    doReject = (message) ->
      (err) ->
        if rejected
          return
        rejected = true
        if !(err instanceof PartiallyHandledError)
          err = new PartiallyHandledError(err, message)
        reject(err)
    splitter = split()
    initialDoReject = doReject("error reading data from file: #{filePath}")
    fileStream = fs.createReadStream(filePath)
    .pipe(splitter)
    .on('end', resolve)
    .on('error', initialDoReject)
    .once 'data', (headerLine) ->
      fileStream.pause()
      fileStream.removeListener('end', resolve)
      fileStream.removeListener('error', initialDoReject)
      # corelogic gives us header names in all caps, with spaces and other punctuation in the names, delimited by tabs
      fields = headerLine.replace(/[^a-zA-Z0-9\t]+/g, ' ').toInitCaps().split('\t')
      pgQuery(dataLoadHelpers.createRawTempTable(tableName, fields).toString())
      .then () -> new Promise (resolve2, reject2) ->
        rejected2 = false
        doReject2 = (message) ->
          (err) ->
            if rejected2
              return
            rejected2 = true
            reject2(new PartiallyHandledError(err, message))
        # stream the rest of the unzipped file directly to COPY FROM, with an appended termination buffer
        transform = (chunk, enc, callback) ->
          if chunk.length > 0
            count += 1
            this.push(chunk)
            this.push('\n')
          callback()
        flush = (callback) ->
          this.push('\\.\n')
          callback()
        copyStart = "COPY \"#{tableName}\" (\"#{fields.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8', NULL '')"
        fileStream
        .pipe(through(transform, flush))
        .pipe(pgClient.query(copyStream.from(copyStart)))
        .on('finish', resolve2)
        .on('error', doReject2("error streaming data to #{tableName}"))
        fileStream.resume()
      .then resolve
      .catch doReject("error executing COPY FROM for #{tableName}")
  .then () ->
    finishQuery = tables.jobQueue.dataLoadHistory()
    .where(raw_table_name: tableName)
    .update raw_rows: count
    pgQuery(finishQuery.toString())
  .then () ->
    pgQuery('COMMIT')
  .then () ->
    return count
  .finally () ->
    # always try to disconnect the db client when we're done, but don't crash if we disconnected prematurely
    try
      pgClient.end()
    catch err
      logger.warn "Error disconnecting raw db connection: #{err}"


# loads all records from a ftp-dropped zip file
loadRawData = (subtask, options) ->
  rawTableName = dataLoadHelpers.getRawTableName subtask, options.rawTableSuffix
  fileBaseName = "corelogic_#{subtask.batch_id}_#{options.rawTableSuffix}"
  ftp = new PromiseFtp()
  ftp.connect
    host: subtask.task_data.host
    user: subtask.task_data.user
    password: encryptor.decrypt(subtask.task_data.password)
  .then () ->
    ftp.get(subtask.data.path)
  .then (zipFileStream) -> new Promise (resolve, reject) ->
    zipFileStream.pipe(fs.createWriteStream("/tmp/#{fileBaseName}.zip"))
    .on('finish', resolve)
    .on('error', reject)
  .then () ->  # just in case this is a retry, do rm -rf
    rimraf.async("/tmp/#{fileBaseName}")
  .then () ->
    fs.mkdirAsync("/tmp/#{fileBaseName}")
  .then () -> new Promise (resolve, reject) ->
    fs.createReadStream("/tmp/#{fileBaseName}.zip")
    .pipe unzip.Extract path: "/tmp/#{fileBaseName}"
    .on('close', resolve)
    .on('error', reject)
  .then () ->
    dataLoadHistory =
      data_source_id: options.dataSourceId
      data_source_type: 'county'
      data_type: subtask.data.type
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    _streamFileToDbTable("/tmp/#{fileBaseName}/#{path.basename(subtask.data.path, '.zip')}.txt", rawTableName, dataLoadHistory, options.rawTableSuffix == 'deed_TXC48123')
  .then (rowsInserted) ->
    return rowsInserted
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to load corelogic data for update")
  .finally () ->
    try
      # try to clean up after ourselves
      rimraf.async("/tmp/#{fileBaseName}")
    catch err
      logger.warn("Error trying to rm -rf temporary directory /tmp/#{fileBaseName}: #{err}")


updateRecord = (stats, diffExcludeKeys, usedKeys, rawData, normalizedData) -> Promise.try () ->
  throw new jobQueue.HardFail('not finished yet')
  # build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  normalizedData.general.unshift(name: 'Address', value: base.address)
  normalizedData.general.unshift(name: 'Status', value: base.status_display)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(tables.propertyData.listing(), base.address)
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
  updateRow = _.extend base, stats, data
  # check for an existing row
  tables.propertyData.listing()
  .select('*')
  .where
    data_source_uuid: updateRow.data_source_uuid
    data_source_id: updateRow.data_source_id
  .then (result) ->
    if !result?.length
      # no existing row, just insert
      updateRow.inserted = stats.batch_id
      tables.propertyData.listing()
      .insert(updateRow)
    else
      # found an existing row, so need to update, but include change log
      result = result[0]
      updateRow.change_history = result.change_history ? []
      changes = dataLoadHelpers.getRowChanges(updateRow, result, diffExcludeKeys)
      if !_.isEmpty changes
        updateRow.change_history.push changes
        updateRow.updated = stats.batch_id
      updateRow.change_history = sqlHelpers.safeJsonArray(tables.propertyData.listing(), updateRow.change_history)
      tables.propertyData.listing()
      .where
        data_source_uuid: updateRow.data_source_uuid
        data_source_id: updateRow.data_source_id
      .update(updateRow)


finalizeData = (subtask, id) ->
  listingsPromise = tables.propertyData.listing()
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
    listing.prior_entries = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listings)
    listing.address = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.address)
    listing.change_history = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.change_history)
    tables.propertyData.combined()
    .insert(listing)

module.exports =
  loadRawData: loadRawData
  updateRecord: updateRecord
  finalizeData: finalizeData
