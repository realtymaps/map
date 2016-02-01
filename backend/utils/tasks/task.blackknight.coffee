Promise = require "bluebird"
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../util.jobQueue'
{SoftFail} = require '../errors/util.error.jobQueue'
tables = require '../../config/tables'
logger = require('../../config/logger').spawn('task:blackknight')
sqlHelpers = require '../util.sql.helpers'
countyHelpers = require './util.countyHelpers'
externalAccounts = require '../../services/service.externalAccounts'
PromiseSftp = require 'promise-sftp'
_ = require 'lodash'
keystore = require '../../services/service.keystore'
TaskImplementation = require './util.taskImplementation'
dbs = require '../../config/dbs'
path = require 'path'
moment = require 'moment'
constants = require './task.blackknight.constants'
validation = require '../util.validation'




_findNewFolders = (ftp, action, processDates, newFolders={}) -> Promise.try () ->
  ftp.list("/Managed_#{action}")
  .then (rootListing) ->
    for dir in rootListing when dir.type == 'd'
      date = dir.name.slice(-8)
      type = constants.tableIdMap[dir.name.slice(0, -8)]
      if !processDates[action]? || !type
        logger.warn("Unexpected directory found in blackknight FTP drop: /Managed_#{action}/#{dir.name}")
        continue
      if processDates[action] >= date
        continue
      newFolders["#{date}_#{action}"] ?= {date, action}
      newFolders["#{date}_#{action}"][type] = {path: "/Managed_#{action}/#{dir.name}", type: type, date: date, action: action}
      logger.info("New blackknight directory found: #{newFolders[date+'_'+action][type].path}")
    newFolders

_checkFolder = (ftp, folderInfo, processLists) -> Promise.try () ->
  logger.debug "Processing blackknight folder: #{folderInfo.path}"
  ftp.list(folderInfo.path)
  .then (folderListing) ->
    for file in folderListing
      if file.name.endsWith('.txt')
        if file.name.startsWith('metadata_')
          continue
        if file.name.indexOf('_Delete_') == -1
          logger.warn("Unexpected file found in blackknight FTP drop: /#{folderInfo.path}/#{file.name}")
          continue
        if file.size == 0
          continue
        fileType = constants.DELETE
      else if !file.name.endsWith('.gz')
        logger.warn("Unexpected file found in blackknight FTP drop: /#{folderInfo.path}/#{file.name}")
        continue
      else
        fileType = folderInfo.action
      fileInfo = _.clone(folderInfo)
      fileInfo.name = file.name
      processLists[fileType].push(fileInfo)

_checkDropChain = (ftp, processInfo, newFolders, drops, i) -> Promise.try () ->
  if i >= drops.length
    logger.debug "Finished processing all blackknight drops; no files found."
    # we've iterated over the whole list
    processInfo.dates[constants.LAST_COMPLETE_CHECK] = moment.utc().format('YYYYMMDD')
    return processInfo
  drop = newFolders[drops[i]]
  if !drop[constants.TAX] || !drop[constants.DEED] || !drop[constants.MORTGAGE]
    return Promise.reject(new Error("Partial #{drop.action} drop for #{drop.date}: #{Object.keys(drop).join(', ')}"))

  logger.debug "Processing blackknight drops for #{drop.date}"
  processInfo.dates[drop.action] = drop.date
  _checkFolder(ftp, drop[constants.TAX], processInfo)
  .then () ->
    _checkFolder(ftp, drop[constants.DEED], processInfo)
  .then () ->
    _checkFolder(ftp, drop[constants.MORTGAGE], processInfo)
  .then () ->
    if processInfo[constants.REFRESH].length + processInfo[constants.UPDATE].length + processInfo[constants.DELETE].length == 0
      # nothing in this folder, move on to the next thing in the drop
      return _checkDropChain(ftp, processInfo, newFolders, drops, i+1)
    # we found files!  resolve the results
    logger.debug "Found blackknight files to process: #{drop.action}/#{drop.date}.  Refresh: #{processInfo[constants.REFRESH].length}, Update: #{processInfo[constants.UPDATE].length}, Delete: #{processInfo[constants.DELETE].length}."
    processInfo.hasFiles = true
    processInfo

_queuePerFileSubtasks = (transaction, subtask, files, action) -> Promise.try () ->
  if !files?.length
    return
  loadDataList = []
  deleteDataList = []
  countDataList = []
  for file in files
    rawTableSuffix = "#{file.name.slice(0, -7)}"
    loadData =
      path: "#{file.path}/#{file.name}"
      rawTableSuffix: rawTableSuffix
      dataType: file.type
      action: file.action
    if action == constants.DELETE
      loadData.fileType = constants.DELETE
    else
      loadData.fileType = constants.LOAD
      countDataList.push
        rawTableSuffix: rawTableSuffix
        dataType: file.type
        deletes: dataLoadHelpers.DELETE.INDICATED
        subset:
          fips_code: file.name.slice(0, 5)
    loadDataList.push(loadData)
  loadRawDataPromise = jobQueue.queueSubsequentSubtask(transaction, subtask, "blackknight_loadRawData", loadDataList, true)
  recordChangeCountsPromise = jobQueue.queueSubsequentSubtask(transaction, subtask, "blackknight_recordChangeCounts", countDataList, true)
  Promise.join loadRawDataPromise, recordChangeCountsPromise, () ->  # empty handler


checkFtpDrop = (subtask) ->
  ftp = new PromiseSftp()
  defaults = {}
  defaults[constants.REFRESH] = '19700101'
  defaults[constants.UPDATE] = '19700101'
  defaults[constants.LAST_COMPLETE_CHECK] = '19700101'
  keystore.getValuesMap(constants.BLACKKNIGHT_PROCESS_DATES, defaultValues: defaults)
  .then (processDates) ->
    externalAccounts.getAccountInfo('blackknight')
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
      _findNewFolders(ftp, constants.REFRESH, processDates)
    .then (newFolders) ->
      _findNewFolders(ftp, constants.UPDATE, processDates, newFolders)
    .then (newFolders) ->
      drops = Object.keys(newFolders).sort()  # sorts by date, with Refresh before Update
      if drops.length == 0
        logger.debug "No new blackknight directories to process"
      else
        logger.debug "Found #{drops.length} blackknight dates to process"
      processInfo = {dates: processDates}
      # reset last complete check unless this run completes
      processInfo.dates[constants.LAST_COMPLETE_CHECK] = '19700101'
      processInfo[constants.REFRESH] = []
      processInfo[constants.UPDATE] = []
      processInfo[constants.DELETE] = []
      _checkDropChain(ftp, processInfo, newFolders, drops, 0)
  .then (processInfo) ->
    ftpEnd = ftp.end()
    # this transaction is important because we don't want the subtasks enqueued below to start showing up as available
    # on their queue out-of-order; normally, subtasks enqueued by another subtask won't be considered as available
    # until the current subtask finishes, but the checkFtpDrop subtask is on a different queue than those being
    # enqueued, and that messes with it.  We could probably fix that edge case, but it would have a steep performance
    # cost, so instead I left it as a caveat to be handled manually (like this) the few times it arises
    dbs.get('main').transaction (transaction) ->
      if processInfo.hasFiles
        deletes = _queuePerFileSubtasks(transaction, subtask, processInfo[constants.DELETE], constants.DELETE)
        refresh = _queuePerFileSubtasks(transaction, subtask, processInfo[constants.REFRESH], constants.REFRESH)
        update = _queuePerFileSubtasks(transaction, subtask, processInfo[constants.UPDATE], constants.UPDATE)
        #finalizePrep = jobQueue.queueSubsequentSubtask(transaction, subtask, "blackknight_finalizeDataPrep", {}, true)
        activate = jobQueue.queueSubsequentSubtask(transaction, subtask, "blackknight_activateNewData", {deletes: dataLoadHelpers.DELETE.INDICATED}, true)
        fileProcessing = Promise.join deletes, refresh, update, activate, () ->  # empty handler
      else
        fileProcessing = Promise.resolve()
      dates = jobQueue.queueSubsequentSubtask(transaction, subtask, 'blackknight_saveProcessDates', dates: processInfo.dates, true)
      Promise.join ftpEnd, fileProcessing, dates, () ->  # empty handler


loadRawData = (subtask) ->
  constants.getColumns(subtask.data.fileType, subtask.data.action, subtask.data.dataType)
  .then (columns) ->
    countyHelpers.loadRawData subtask,
      dataSourceId: 'blackknight'
      columnsHandler: columns
      delimiter: '\t'
      sftp: true
  .then (numRows) ->
    if subtask.data.fileType == constants.DELETE
      nextSubtaskName = "blackknight_deleteData"
    else
      nextSubtaskName = "blackknight_normalizeData"
    jobQueue.queueSubsequentPaginatedSubtask null, subtask, numRows, constants.NUM_ROWS_TO_PAGINATE, nextSubtaskName,
      rawTableSuffix: subtask.data.rawTableSuffix
      dataType: subtask.data.dataType
      action: subtask.data.action

saveProcessedDates = (subtask) ->
  keystore.setValuesMap(subtask.data.dates, namespace: constants.BLACKKNIGHT_PROCESS_DATES)

deleteData = (subtask) ->
  rawTableName = dataLoadHelpers.buildUniqueSubtaskName(subtask)
  # get rows for this subtask
  normalDataTable = tables.property[subtask.data.dataType]
  tables.buildRawTableQuery(rawTableName)
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
  .then (rows) ->
    promises = for row in rows then do (row) ->
      if subtask.data.action == constants.REFRESH
        normalDataTable()
        .where
          data_source_id: 'blackknight'
          fips_code: row['FIPS Code']
        .whereNull('deleted')
        .update(deleted: subtask.batch_id)
      else
        if subtask.data.dataType == constants.TAX
          # get validation for parcel_id
          dataLoadHelpers.getValidationInfo('county', 'blackknight', subtask.data.dataType, 'base', 'parcel_id')
          .then (validationInfo) ->
            Promise.props(_.mapValues(validationInfo.validationMap, validation.validateAndTransform.bind(null, row)))
          .then (normalizedData) ->
            normalDataTable()
            .where
              data_source_id: 'blackknight'
              fips_code: row['FIPS Code']
              parcel_id: normalizedData.parcel_id
            .whereNull('deleted')
            .update(deleted: subtask.batch_id)
        else
          normalDataTable()
          .where
            data_source_id: 'blackknight'
            fips_code: row['FIPS Code']
            data_source_uuid: row['BKFS Internal PID']
          .whereNull('deleted')
          .update(deleted: subtask.batch_id)
    Promise.all promises

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: 'blackknight'
    dataSourceType: 'county'
    buildRecord: countyHelpers.buildRecord
  .then (successes) ->
    if successes.length == 0
      logger.debug('No successful data updates from normalize subtask: '+JSON.stringify(i: subtask.data.i, of: subtask.data.of, rawTableSuffix: subtask.data.rawTableSuffix))
      return
    jobQueue.queueSubsequentSubtask null, subtask, "blackknight_finalizeData",
      cause: subtask.data.dataType
      i: subtask.data.i
      of: subtask.data.of
      rawTableSuffix: subtask.data.rawTableSuffix
      count: successes.length
      ids: successes

###
finalizeDataPrep = (subtask) ->
  Promise.map ['deed', 'tax', 'mortgage'], (source) ->
    tables.property[source]()
    .select('rm_property_id')
    .where(batch_id: subtask.batch_id)
    .then (ids) ->
      _.pluck(ids, 'rm_property_id')
  .then (lists) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, _.union(lists), constants.NUM_ROWS_TO_PAGINATE, "blackknight_finalizeData")
###

finalizeData = (subtask) ->
  Promise.map subtask.data.ids, countyHelpers.finalizeData.bind(null, subtask)


ready = () ->
  defaults = {}
  defaults[constants.REFRESH] = '19700101'
  defaults[constants.UPDATE] = '19700101'
  defaults[constants.LAST_COMPLETE_CHECK] = '19700101'
  keystore.getValuesMap(constants.BLACKKNIGHT_PROCESS_DATES, defaultValues: defaults)
  .then (processDates) ->
    if processDates[constants.LAST_COMPLETE_CHECK] != moment.utc().format('YYYYMMDD')
      # needs to run using regular logic
      return undefined
    dayOfWeek = moment.utc().isoWeekday()
    if dayOfWeek == 7 || dayOfWeek == 1
      # Sunday or Monday, because drops don't happen at the end of Saturday and Sunday
      return false
    yesterday = moment.utc().subtract(1, 'day').format('YYYYMMDD')
    if processDates[constants.REFRESH] == yesterday && processDates[constants.UPDATE] == yesterday
      # we've already processed yesterday's data
      return false
    # no overrides, needs to run using regular logic
    return undefined


subtasks =
  checkFtpDrop: checkFtpDrop
  loadRawData: loadRawData
  deleteData: deleteData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData

module.exports = new TaskImplementation(subtasks, ready)
