_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require '../errors/util.error.partiallyHandledError'
{SoftFail} = require '../errors/util.error.jobQueue'
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
externalAccounts = require '../../services/service.externalAccounts'
PromiseFtp = require 'promise-ftp'
PromiseSftp = require 'promise-sftp'
unzip = require 'unzip2'
fs = require 'fs'
path = require 'path'
through = require 'through2'
rimraf = require 'rimraf'
zlib = require 'zlib'


# loads all records from a ftp-dropped zip file
loadRawData = (subtask, options) ->
  rawTableName = dataLoadHelpers.buildUniqueSubtaskName(subtask)
  fileBaseName = dataLoadHelpers.buildUniqueSubtaskName(subtask, subtask.task_name)
  if options.sftp
    ftp = new PromiseSftp()
  else
    ftp = new PromiseFtp()
  filetype = options.processingType || subtask.data.path.substr(subtask.data.path.lastIndexOf('.')+1)
  dataStreamPromise = externalAccounts.getAccountInfo(subtask.task_name)
  .then (accountInfo) ->
    ftp.connect
      host: accountInfo.url
      user: accountInfo.username
      password: accountInfo.password
      autoReconnect: true
    .catch (err) ->
      if err.level == 'client-authentication'
        throw new SoftFail('FTP authentication error')
      else
        throw err
  .then () ->
    if options.sftp
      ftp.fastGet(subtask.data.path, "/tmp/#{fileBaseName}.#{filetype}")
    else
      ftp.get(subtask.data.path)
      .then (dataStream) -> new Promise (resolve, reject) ->
        dataStream.pipe(fs.createWriteStream("/tmp/#{fileBaseName}.#{filetype}"))
        .on('finish', resolve)
        .on('error', reject)
  .then () ->
    ftp.logout()

  switch filetype
    when 'zip'
      dataStreamPromise = dataStreamPromise
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
        "/tmp/#{fileBaseName}/#{path.basename(subtask.data.path, '.zip')}.txt"
    when 'gz'
      dataStreamPromise = dataStreamPromise
      .then () -> new Promise (resolve, reject) ->
        fs.createReadStream("/tmp/#{fileBaseName}.gz")
        .pipe(zlib.createGunzip())
        .pipe fs.createWriteStream("/tmp/#{fileBaseName}")
        .on('close', resolve)
        .on('error', reject)
      .then () ->
        "/tmp/#{fileBaseName}"
    else
      dataStreamPromise = dataStreamPromise
      .then () ->
        "/tmp/#{fileBaseName}.#{filetype}"

  dataStreamPromise
  .then (localFilePath) ->
    fs.createReadStream(localFilePath)
  .then (rawDataStream) ->
    dataLoadHistory =
      data_source_id: options.dataSourceId
      data_source_type: 'county'
      data_type: subtask.data.dataType
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    objectDataStream = utilStreams.delimitedTextToObjectStream(rawDataStream, options.delimiter, options.columnsHandler)
    dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, objectDataStream)
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to load #{subtask.task_name} data for update")
  .finally () ->
    try
      # try to clean up after ourselves
      rimraf.async("/tmp/#{fileBaseName}*")
    catch err
      logger.warn("Error trying to rm -rf temporary files /tmp/#{fileBaseName}*: #{err}")


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  update_type = base.update_type
  delete base.update_type
  normalizedData.general ?= []
  normalizedData.general.unshift(name: 'Address', value: base.address)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(base.address)
    shared_groups:
      general: normalizedData.general
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
  mortgageEntriesPromise = tables.property.mortgage()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderByRaw('close_date ASC NULLS LAST')
  # TODO: does this need to be discriminated further?  speculators can resell a property the same day they buy it with
  # TODO: simultaneous closings, how do we properly sort to account for that?
  parcelsPromise = tables.property.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(rm_property_id: id)
  Promise.join taxEntriesPromise, deedEntriesPromise, mortgageEntriesPromise, parcelsPromise, (taxEntries=[], deedEntries=[], mortgageEntries=[], parcel=[]) ->
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
    ###
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
    ###

    # TODO: consider going through salesHistory to make it essentially a diff, with changed values only for certain
    # TODO: static data fields?

    # now that we have an ordered sales history, overwrite that into the tax record

    saleFields = ['price', 'close_date', 'parcel_id', 'owner_name', 'owner_name_2', 'address']
    tax.subscriber_groups.mortgage = mortgageEntries
    lastSale = deedEntries.pop()
    if lastSale?
      tax.subscriber_groups.owner = lastSale.subscriber_groups.owner
      tax.subscriber_groups.deed = lastSale.subscriber_groups.deed
      for field in saleFields
        tax[field] = lastSale[field]
    tax.shared_groups.sale = []
    for deedInfo in deedEntries
      tax.shared_groups.sale.push(price: deedInfo.price, close_date: deedInfo.close_date)
      tax.subscriber_groups.deedHistory.push(deedInfo.subscriber_groups.owner.concat(deedInfo.subscriber_groups.deed))

    tables.property.combined()
    .insert(tax)


###
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
###

module.exports =
  loadRawData: loadRawData
  buildRecord: buildRecord
  finalizeData: finalizeData
