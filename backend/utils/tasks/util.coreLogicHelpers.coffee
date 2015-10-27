_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require '../errors/util.error.partiallyHandledError'
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
PromiseFtp = require 'promise-ftp'
encryptor = require '../../config/encryptor'
unzip = require 'unzip2'
split = require 'split'
fs = require 'fs'
path = require 'path'
through = require 'through2'
rimraf = require 'rimraf'


_fileToDbStreamer = (filePath) ->
  # stream the contents of the file into a COPY FROM query
  (tableName, promiseQuery, streamQuery) ->
    count = 0
    new Promise (resolve, reject) ->
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
        promiseQuery(dataLoadHelpers.createRawTempTable(tableName, fields).toString())
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
              this.push(utilStreams.pgStreamEscape(chunk))
              this.push('\n')
            callback()
          flush = (callback) ->
            this.push('\\.\n')
            callback()
          copyStart = "COPY \"#{tableName}\" (\"#{fields.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8', NULL '')"
          fileStream
          .pipe(through(transform, flush))
          .pipe(streamQuery(copyStream.from(copyStart)))
          .on('finish', resolve2)
          .on('error', doReject2("error streaming data to #{tableName}"))
          fileStream.resume()
        .then resolve
        .catch doReject("error executing COPY FROM for #{tableName}")
    .then () ->
      count


# loads all records from a ftp-dropped zip file
loadRawData = (subtask, options) ->
  rawTableName = dataLoadHelpers.buildUniqueSubtaskName(subtask)
  fileBaseName = dataLoadHelpers.buildUniqueSubtaskName(subtask, 'corelogic')
  ftp = new PromiseFtp()
  ftp.connect
    host: subtask.task_data.host
    user: subtask.task_data.user
    password: encryptor.decrypt(subtask.task_data.password)
    autoReconnect: true
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
      data_type: subtask.data.dataType
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    filePath = "/tmp/#{fileBaseName}/#{path.basename(subtask.data.path, '.zip')}.txt"
    dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, _fileToDbStreamer(filePath))
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


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  update_type = base.update_type
  delete base.update_type
  normalizedData.general.unshift(name: 'Address', value: base.address)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(base.address)
    shared_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      sale: normalizedData.sale || []
      building: normalizedData.building || []
      taxes: normalizedData.taxes || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    subscriber_groups:
      owner: normalizedData.owner || []
      deed: normalizedData.deed || []
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: if update_type == 'D' then stats.batch_id else null
  _.extend base, stats, data


finalizeData = (subtask, id) ->
  taxEntriesPromise = tables.property.tax()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderByRaw('close_date DESC NULLS FIRST')
  deedEntriesPromise = tables.property.deed()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderByRaw('close_date ASC NULLS LAST')
  # TODO: does this need to be discriminated further?  speculators can resell a property the same day they buy it with
  # TODO: simultaneous closings, how do we property sort to account for that?
  parcelsPromise = tables.property.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(rm_property_id: id)
  Promise.join taxEntriesPromise, deedEntriesPromise, parcelsPromise, (taxEntries=[], deedEntries=[], parcel=[]) ->
    if taxEntries.length == 0
      # not sure if this should ever be possible, but we'll handle it anyway
      return tables.property.deletes()
      .insert
        rm_property_id: id
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id
    tax = dataLoadHelpers.finalizeEntry(taxEntries)
    tax.data_source_type = 'county'
    _.extend(tax, parcel[0])
    currentSale = []
    priorSale = []
    for field in tax.sale
      if field.name.startsWith('Prior ')
        field.name = field.slice(6)
        priorSale.push(field)
      else
        currentSale.push(field)
    saleFields = ['price', 'close_date', 'parcel_id', 'owner_name', 'owner_name_2', 'address']
    current = _.pick(tax, saleFields)
    current.subscriber_groups = _.pick(tax.subscriber_groups, 'owner', 'deed')
    current.shared_groups = {sale: currentSale}
    delete tax.subscriber_groups.owner
    delete tax.subscriber_groups.deed
    delete tax.shared_groups.sale
    prior = _.pick(tax, _.map(saleFields, (fieldName) -> "prior_#{fieldName}"))
    prior.subscriber_groups = {}
    prior.shared_groups = {sale: priorSale}
    for field in _.map(saleFields, (fieldName) -> "prior_#{fieldName}")
      delete tax[field]
    salesHistory = []
    if deedEntries.length
      while deed = deedEntries.pop()
        if deed.close_date.getTime() > current.close_date.getTime()
          salesHistory.push(deed)
        else if deed.close_date.getTime() == current.close_date.getTime()
          # merge them, they're the same sale
          _listExtend(deed.subscriber_groups.owner, current.subscriber_groups.owner)
          _listExtend(deed.subscriber_groups.deed, current.subscriber_groups.deed)
          _listExtend(deed.shared_groups.sale, current.shared_groups.sale)
          salesHistory.push(deed)
          current = null
          break
        else
          # insert the current tax sale into the list and then pick back up with the prior tax sale
          salesHistory.push(current)
          deedEntries.push(deed)
          current = null
          break
      if current != null
        # we never found a spot to insert, so go ahead and put them both in
        salesHistory.push(current, prior)
      else
        # now do sort of the same thing for prior
        while deed = deedEntries.pop()
          if deed.close_date.getTime() > prior.close_date.getTime()
            salesHistory.push(deed)
          else if deed.close_date.getTime() == prior.close_date.getTime()
            # we would merge them, but prior has nothing to add
            salesHistory.push(deed)
            break
          else
            salesHistory.push(prior)
            salesHistory.push(deed)
            break
        # through any remaining deeds in
        salesHistory.concat(deedEntries)
    else
      salesHistory = [current, prior]
    
    # TODO: consider going through salesHistory to make it essentially a diff, with changed values only for certain
    # TODO: static data fields?

    # now that we have an ordered sales history, overwrite that into the tax record
    lastSale = salesHistory.shift()
    tax.subscriber_groups.owner = lastSale.subscriber_groups.owner
    tax.subscriber_groups.deed = lastSale.subscriber_groups.deed
    for field in saleFields
      tax[field] = lastSale[field]
    tax.shared_groups.sale = salesHistory
    
    tables.property.combined()
    .insert(tax)


_listExtend = (list1, list2) ->
  list1Map = dataLoadHelpers.getValues(list1)
  i=0
  j=0
  while j<list2.length
    if list1[i].name == list2[j].name
      # field exists on both sides, keep the list1 value and increment both sides
      i++
      j++
    else if list1Map[list2[j].name]?
      # fields don't match, but the list2 field exists somewhere in list1 -- we must be looking at a unique field in
      # list1, so increment past it
      i++
    else
      # fields don't match, and the list2 field is unique -- splice it into list1, then increment past it
      list1.splice(i, 0, list2[j])
      i++
      j++
      
    
module.exports =
  loadRawData: loadRawData
  buildRecord: buildRecord
  finalizeData: finalizeData
