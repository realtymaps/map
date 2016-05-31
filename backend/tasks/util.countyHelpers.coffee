_ = require 'lodash'
Promise = require 'bluebird'
PromiseFtp = require 'promise-ftp'
PromiseSftp = require 'promise-sftp'
unzip = require 'unzip2'
fs = require 'fs'
path = require 'path'
rimraf = require 'rimraf'
zlib = require 'zlib'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
utilStreams = require '../utils/util.streams'
logger = require('../config/logger').spawn('task:util:countyHelpers')
tables = require '../config/tables'
dataLoadHelpers = require './util.dataLoadHelpers'
externalAccounts = require '../services/service.externalAccounts'
internals = require './util.countyHelpers.internals'
parcelHelpers = null  # required later to avoid circular dependency


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


finalizeData = ({subtask, id, data_source_id, transaction, delay, finalizedParcel, forceFinalize, update_source}) ->
  parcelHelpers ?= require './util.parcelHelpers'  # delayed require due to circular dependency

  internals.finalizeDataTax {subtask, id, data_source_id, transaction, forceFinalize}
  .then (taxEntries) ->
    if !taxEntries?
      return
    internals.finalizeDataDeed {subtask, id, data_source_id, forceFinalize}
    .then (deedEntries) ->
      if !deedEntries?
        return
      mortgagePromise = internals.finalizeDataMortgage {subtask, id, data_source_id}
      if finalizedParcel?
        parcelsPromise = Promise.resolve([finalizedParcel])
      else
        parcelsPromise = parcelHelpers.getParcelsPromise {rm_property_id: id, transaction}
      Promise.join mortgagePromise, parcelsPromise, (mortgageEntries, parcelEntries) ->
        internals.finalizeJoin {
          subtask
          id
          data_source_id
          transaction
          delay
          taxEntries
          deedEntries
          mortgageEntries
          parcelEntries
          update_source
        }


module.exports =
  loadRawData: loadRawData
  buildRecord: buildRecord
  finalizeData: finalizeData
