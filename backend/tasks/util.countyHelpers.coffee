_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require '../utils/util.streams'
dbs = require '../config/dbs'
config = require '../config/config'
logger = require '../config/logger'
jobQueue = require '../services/service.jobQueue'
validation = require '../utils/util.validation'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'
externalAccounts = require '../services/service.externalAccounts'
PromiseFtp = require 'promise-ftp'
PromiseSftp = require 'promise-sftp'
unzip = require 'unzip2'
fs = require 'fs'
path = require 'path'
rimraf = require 'rimraf'
zlib = require 'zlib'


# loads all records from a ftp-dropped zip file
loadRawData = (subtask, options) ->
  rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))
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
        try
          fs.createReadStream("/tmp/#{fileBaseName}.zip")
          .pipe unzip.Extract path: "/tmp/#{fileBaseName}"
          .on('close', resolve)
          .on('error', reject)
        catch err
          reject new SoftFail(err.toString())
      .then () ->
        "/tmp/#{fileBaseName}/#{path.basename(subtask.data.path, '.zip')}.txt"
    when 'gz'
      dataStreamPromise = dataStreamPromise
      .then () -> new Promise (resolve, reject) ->
        try
          fs.createReadStream("/tmp/#{fileBaseName}.gz")
          .pipe(zlib.createGunzip())
          .pipe fs.createWriteStream("/tmp/#{fileBaseName}")
          .on('close', resolve)
          .on('error', reject)
        catch err
          reject new SoftFail(err.toString())
      .then () ->
        "/tmp/#{fileBaseName}"
    else
      dataStreamPromise = dataStreamPromise
      .then () ->
        "/tmp/#{fileBaseName}.#{filetype}"

  dataStreamPromise
  .then (localFilePath) ->
    fs.createReadStream(localFilePath)
  .catch isUnhandled, (err) ->
    throw new SoftFail(err.toString())
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
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  if dataType == 'tax'
    group1 = 'general'
    group2 = 'owner'
  else if dataType == 'deed'
    group1 = 'deed'
    group2 = 'owner'
  else if dataType == 'mortgage'
    group1 = 'mortgage'
    group2 = 'mortgage'
  normalizedData[group1] ?= []
  normalizedData[group2] ?= []
  normalizedData[group1].unshift(name: 'Address', value: base.address)
  normalizedData[group2].unshift(name: "Owner 1", value: base.owner_name)
  normalizedData[group2].unshift(name: "Owner 2", value: base.owner_name_2)
  normalizedData[group2].unshift(name: "Owner's Address", value: base.owner_address)
  if dataType == 'tax'
    data =
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
        mortgage: normalizedData.mortgage || []
  else if dataType == 'deed'
    data =
      shared_groups: {}
      subscriber_groups:
        owner: normalizedData.owner
        deed: normalizedData.deed
  else if dataType == 'mortgage'
    data =
      shared_groups: {}
      subscriber_groups:
        mortgage: normalizedData.mortgage
  commonData =
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: if update_type == 'D' then stats.batch_id else null
  _.extend base, stats, data, commonData


finalizeData = ({subtask, id, data_source_id}) ->
  tables.property.tax(subid: subtask.data.normalSubid)
  .select('*')
  .where
    rm_property_id: id
    data_source_id: data_source_id || subtask.task_name
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderByRaw('close_date DESC NULLS LAST')
  .then (taxEntries=[]) ->
    if taxEntries.length == 0
      # not sure if this should ever be possible, but we'll handle it anyway
      return tables.deletes.property()
      .insert
        rm_property_id: id
        data_source_id: data_source_id || subtask.task_name
        batch_id: subtask.batch_id
    if subtask.data.cause != 'tax' && taxEntries[0]?.batch_id == subtask.batch_id
      # since the same rm_property_id might get enqueued for finalization multiple times, we GTFO based on the priority
      # of the given enqueue source , in the following order: tax, deed, mortgage.  So if this instance wasn't enqueued
      # because of tax data, but the tax data appears to have been updated in this same batch, we bail and let tax take
      # care of it.
      return
    tables.property.deed(subid: subtask.data.normalSubid)
    .select('*')
    .where
      rm_property_id: id
      data_source_id: data_source_id || subtask.task_name
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('close_date ASC NULLS FIRST')
    .then (deedEntries=[]) ->
      if subtask.data.cause == 'mortgage' && deedEntries[0]?.batch_id == subtask.batch_id
        # see above comment about GTFO shortcut logic.  This part lets mortgage give priority to deed.
        return
      mortgagePromise = tables.property.mortgage(subid: subtask.data.normalSubid)
      .select('*')
      .where
        rm_property_id: id
        data_source_id: data_source_id || subtask.task_name
      .whereNull('deleted')
      .orderBy('rm_property_id')
      .orderBy('deleted')
      .orderByRaw('close_date ASC NULLS FIRST')
      parcelsPromise = tables.property.parcel()
      .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
      .where(rm_property_id: id)
      Promise.join mortgagePromise, parcelsPromise, (mortgageEntries=[], parcel=[]) ->
        # TODO: does this need to be discriminated further?  speculators can resell a property the same day they buy it with
        # TODO: simultaneous closings, how do we properly sort to account for that?
        tax = dataLoadHelpers.finalizeEntry(taxEntries)
        tax.data_source_type = 'county'
        _.extend(tax, parcel[0])

        # TODO: consider going through salesHistory to make it essentially a diff, with changed values only for certain
        # TODO: static data fields?

        # now that we have an ordered sales history, overwrite that into the tax record
        saleFields = ['price', 'close_date', 'parcel_id', 'owner_name', 'owner_name_2', 'address', 'owner_address', 'property_type', 'zoning']
        tax.subscriber_groups.mortgage = mortgageEntries
        lastSale = deedEntries.pop()
        if lastSale?
          tax.subscriber_groups.owner = lastSale.subscriber_groups.owner
          tax.subscriber_groups.deed = lastSale.subscriber_groups.deed
          for field in saleFields
            tax[field] = lastSale[field]
          # save the MLS promoted values for easier access
          promotedValues =
            owner_name: lastSale.owner_name
            owner_name_2: lastSale.owner_name_2
            zoning: lastSale.zoning
        else
          # save the MLS promoted values for easier access
          promotedValues =
            owner_name: tax.owner_name
            owner_name_2: tax.owner_name_2
            zoning: tax.zoning
        tax.shared_groups.sale = []
        tax.subscriber_groups.deedHistory = []
        for deedInfo in deedEntries
          tax.shared_groups.sale.push(price: deedInfo.price, close_date: deedInfo.close_date)
          tax.subscriber_groups.deedHistory.push(deedInfo.subscriber_groups.owner.concat(deedInfo.subscriber_groups.deed))

        Promise.delay(100)  #throttle for heroku's sake
        .then () ->
          if !_.isEqual(promotedValues, tax.promotedValues)
            # need to save back promoted values to the normal table
            tables.property.tax(subid: subtask.data.normalSubid)
            .where
              data_source_id: data_source_id || subtask.task_name
              data_source_uuid: tax.data_source_uuid
            .update(promoted_values: promotedValues)
          else
            Promise.resolve()
        .then () ->
          dbs.get('main').transaction (transaction) ->
            tables.property.combined(transaction: transaction)
            .where
              rm_property_id: id
              data_source_id: data_source_id || subtask.task_name
              active: false
            .delete()
            .then () ->
              tables.property.combined(transaction: transaction)
              .insert(tax)


###
# old finalizeData code from corelogic
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
