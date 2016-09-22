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
logger = require('../config/logger').spawn('task:countyHelpers')
tables = require '../config/tables'
dataLoadHelpers = require './util.dataLoadHelpers'
externalAccounts = require '../services/service.externalAccounts'
internals = require './util.countyHelpers.internals'
parcelHelpers = null  # required later to avoid circular dependency
awsService = require '../services/service.aws'


# using FTP `account`, send files from `source` (ftp) to `target` (local) given certain `options`
_fetchFTP = (account, source, target, options) ->
  if options.sftp
    ftp = new PromiseSftp()
  else
    ftp = new PromiseFtp()

  externalAccounts.getAccountInfo(account)
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
      ftp.fastGet(source, target)
    else
      ftp.get(source)
      .then (dataStream) -> new Promise (resolve, reject) ->
        dataStream.pipe(fs.createWriteStream(target))
        .on('finish', resolve)
        .on('error', reject)
  .then () ->
    ftp.logout()

# using an S3 bucket `account`, send files from `source` (s3) to `target` (local) given certain `options`
_fetchS3 = (account, source, target, options) ->
  config =
    extAcctName: account
    Key: source
    stream: true

  awsService.getObject(config)
  .then (streamable) -> new Promise (resolve, reject) ->
    streamable.createReadStream().pipe(fs.createWriteStream(target))
    .on 'finish', (details) ->
      resolve(details)
    .on('error', reject)
  .catch (err) ->
    throw new SoftFail("S3 `getObject` error: #{err}")


# loads all records from a specified source (e.g. FTP or S3)
loadRawData = (subtask, options) ->
  rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))
  doDebug = rawTableName.endsWith('_blackknight_tax_R_12001_20160824')
  if doDebug then console.log('@@@@@@@@@@@@@@@@@@@@@@@@@ countyHelpers.loadRawData STARTING')
  fileBaseName = dataLoadHelpers.buildUniqueSubtaskName(subtask, subtask.task_name)
  filetype = options.processingType || subtask.data.path.substr(subtask.data.path.lastIndexOf('.')+1)

  target = "/tmp/#{fileBaseName}.#{filetype}"
  source = subtask.data.path

  # transfer files from a configured source...
  if doDebug then console.log('@@@@@@@@@@@@@@@@@@@@@@@@@ countyHelpers.loadRawData DOWNLOADING')
  if options.s3account
    dataStreamPromise = _fetchS3(options.s3account, source, target, options)
  else
    # FTP / SFTP check done in `_fetchFTP`
    dataStreamPromise = _fetchFTP(subtask.task_name, source, target, options)

  # unzip the transfered files...
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
          fs.createReadStream(target)
          .pipe(zlib.createGunzip())
          .pipe fs.createWriteStream("/tmp/#{fileBaseName}")
          .on 'close', (detail) ->
            resolve(detail)
          .on('error', reject)
        catch err
          reject new SoftFail(err.toString())
      .then () ->
        "/tmp/#{fileBaseName}"
    else
      dataStreamPromise = dataStreamPromise
      .then () ->
        "/tmp/#{fileBaseName}.#{filetype}"

  # process files...
  dataStreamPromise
  .then (localFilePath) ->
    fs.createReadStream(localFilePath)
  .catch isUnhandled, (err) ->
    throw new SoftFail(err.toString())
  .then (rawDataStream) ->
    if doDebug then console.log('@@@@@@@@@@@@@@@@@@@@@@@@@ countyHelpers.loadRawData READING FROM FILE')
    dataLoadHistory =
      data_source_id: options.dataSourceId
      data_source_type: 'county'
      data_type: subtask.data.dataType
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    if doDebug then console.log('@@@@@@@@@@@@@@@@@@@@@@@@@ countyHelpers.loadRawData INITIALIZING DATA STREAM')
    objectDataStream = utilStreams.delimitedTextToObjectStream(rawDataStream, options.delimiter, options.columnsHandler)
    if doDebug then console.log('@@@@@@@@@@@@@@@@@@@@@@@@@ countyHelpers.loadRawData MANAGING DATA STREAM')
    dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, objectDataStream)
  .then () ->
    if doDebug then console.log('@@@@@@@@@@@@@@@@@@@@@@@@@ countyHelpers.loadRawData DONE')
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
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  if dataType == 'tax'
    data =
      shared_groups:
        general: normalizedData.general || []
        details: normalizedData.details || []
        building: normalizedData.building || []
        taxes: normalizedData.taxes || []
        lot: normalizedData.lot || []
        location: normalizedData.location || []
        restrictions: normalizedData.restrictions || []
      subscriber_groups:
        owner: normalizedData.owner || []
        deed: normalizedData.deed || []
  else if dataType == 'deed'
    data =
      shared_groups: {}
      subscriber_groups:
        owner: normalizedData.owner || []
        deed: normalizedData.deed || []
  else if dataType == 'mortgage'
    data =
      shared_groups: {}
      subscriber_groups:
        mortgage: normalizedData.mortgage || []
  commonData =
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
  _.extend base, stats, data, commonData


finalizeData = ({subtask, id, data_source_id, transaction, finalizedParcel, forceFinalize}) ->
  internals.__troubleshoot__(id, 'finalizeData start')
  parcelHelpers ?= require './util.parcelHelpers'  # delayed require due to circular dependency

  internals.finalizeDataTax {subtask, id, data_source_id, transaction, forceFinalize}
  .then (taxEntries) ->
    if !taxEntries?
      return
    internals.finalizeDataDeed {subtask, id, data_source_id, forceFinalize}
    .then (deedEntries) ->
      if !deedEntries?
        return
      mortgagePromise = internals.finalizeDataMortgage({subtask, id, data_source_id})
      if finalizedParcel?
        parcelsPromise = Promise.resolve([finalizedParcel])
      else
        parcelsPromise = parcelHelpers.getParcelsPromise {rm_property_id: id, transaction}
      Promise.join mortgagePromise, parcelsPromise, (mortgageEntries, parcelEntries) ->
        internals.__troubleshoot__(id, 'finalizeData: got data, doing join')
        internals.finalizeJoin {
          subtask
          id
          data_source_id
          transaction
          taxEntries
          deedEntries
          mortgageEntries
          parcelEntries
        }


module.exports =
  loadRawData: loadRawData
  buildRecord: buildRecord
  finalizeData: finalizeData
