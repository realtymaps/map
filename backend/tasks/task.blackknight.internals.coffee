_ = require 'lodash'
Promise = require "bluebird"
svc = require '../services/service.dataSource'
logger = require('../config/logger').spawn('task:blackknight:internals')
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
moment = require 'moment'


NUM_ROWS_TO_PAGINATE = 2500
BLACKKNIGHT_PROCESS_DATES = 'blackknight process dates'
BLACKKNIGHT_COPY_DATES = 'blackknight copy dates'
TAX = 'tax'
DEED = 'deed'
MORTGAGE = 'mortgage'
REFRESH = 'Refresh'
UPDATE = 'Update'
NO_NEW_DATA_FOUND = 'no new data found'
DELETE = 'Delete'
LOAD = 'Load'
tableIdMap =
  ASMT: 'tax'
  Deed: 'deed'
  SAM: 'mortgage'


columns = {}
columns[DELETE] = {}
columns[DELETE][REFRESH] = {}
columns[DELETE][REFRESH][TAX] = [
  "FIPS Code"
  "Edition"
  "Load Date"
]
columns[DELETE][REFRESH][DEED] = [
  "FIPS Code"
]
columns[DELETE][REFRESH][MORTGAGE] = [
  "FIPS Code"
]

columns[DELETE][UPDATE] = {}
columns[DELETE][UPDATE][TAX] = [
  "FIPS Code"
  "Assessor’s Parcel Number"
  "Edition"
  "Load Date"
]
columns[DELETE][UPDATE][DEED] = [
  "FIPS Code"
  "BK PID"
]
columns[DELETE][UPDATE][MORTGAGE] = [
  "FIPS Code"
  "BK PID"
]

columns[LOAD] = {}
columns[LOAD][REFRESH] = {}
# load columns are the same whether refresh or update
columns[LOAD][UPDATE] = columns[LOAD][REFRESH]


findNewFolders = (ftp, action, processDates, newFolders={}) -> Promise.try () ->
  ftp.list("/Managed_#{action}")
  .then (rootListing) ->
    for dir in rootListing when dir.type == 'd'
      date = dir.name.slice(-8)
      type = tableIdMap[dir.name.slice(0, -8)]
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
          logger.warn("Unexpected file found in blackknight FTP drop: #{folderInfo.path}/#{file.name}")
          continue
        if file.size == 0
          continue
        fileType = DELETE
      else if !file.name.endsWith('.gz')
        logger.warn("Unexpected file found in blackknight FTP drop: #{folderInfo.path}/#{file.name}")
        continue
      else if (file.name.endsWith('.gz') && !file.name.startsWith('12021'))
        logger.warn("Ignoring file due to FIPS code: #{folderInfo.path}/#{file.name}")
        continue
      else
        fileType = folderInfo.action
      fileInfo = _.clone(folderInfo)
      fileInfo.name = file.name
      processLists[fileType].push(fileInfo)


checkDropChain = (ftp, processInfo, newFolders, drops, i) -> Promise.try () ->
  if i >= drops.length
    logger.debug "Finished processing all blackknight drops; no files found."
    # we've iterated over the whole list
    processInfo.dates[NO_NEW_DATA_FOUND] = moment.utc().format('YYYYMMDD')
    return processInfo
  drop = newFolders[drops[i]]
  if !drop[TAX] || !drop[DEED] || !drop[MORTGAGE]
    return Promise.reject(new Error("Partial #{drop.action} drop for #{drop.date}: #{Object.keys(drop).join(', ')}"))

  logger.debug "Processing blackknight drops for #{drop.date}"
  processInfo.dates[drop.action] = drop.date
  _checkFolder(ftp, drop[TAX], processInfo)
  .then () ->
    _checkFolder(ftp, drop[DEED], processInfo)
  .then () ->
    _checkFolder(ftp, drop[MORTGAGE], processInfo)
  .then () ->
    if processInfo[REFRESH].length + processInfo[UPDATE].length + processInfo[DELETE].length == 0
      # nothing in this folder, move on to the next thing in the drop
      return checkDropChain(ftp, processInfo, newFolders, drops, i+1)
    # we found files!  resolve the results
    logger.debug "Found blackknight files to process: #{drop.action}/#{drop.date}.  Refresh: #{processInfo[REFRESH].length}, Update: #{processInfo[UPDATE].length}, Delete: #{processInfo[DELETE].length}."
    processInfo.hasFiles = true
    processInfo


queuePerFileSubtasks = (transaction, subtask, files, action, now) -> Promise.try () ->
  if !files?.length
    return
  loadDataList = []
  countDataList = []
  fipsCodes = {}
  for file in files
    loadData =
      path: "#{file.path}/#{file.name}"
      dataType: file.type
      action: file.action
    if action == DELETE
      loadData.fileType = DELETE
      loadData.rawTableSuffix = "#{file.name.slice(0, -4)}"
    else
      loadData.fileType = LOAD
      loadData.rawTableSuffix = "#{file.name.slice(0, -7)}"
      loadData.normalSubid = file.name.slice(0, 5)
      loadData.startTime = now
      fipsCodes[loadData.normalSubid] = true
      countDataList.push
        rawTableSuffix: loadData.rawTableSuffix
        normalSubid: loadData.normalSubid
        dataType: file.type
        deletes: dataLoadHelpers.DELETE.INDICATED
        action: action
        indicateDeletes: (action == REFRESH)  # only set this flag for refreshes, not updates
    loadDataList.push(loadData)
  loadRawDataPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "loadRawData", manualData: loadDataList, replace: true, concurrency: 10})
  recordChangeCountsPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "recordChangeCounts", manualData: countDataList, replace: true})
  Promise.join loadRawDataPromise, recordChangeCountsPromise, () ->
    fipsCodes


_getColumnsImpl = (fileType, action, dataType) ->
  svc.exposeKnex()
  .getAll(data_source_id:'blackknight', data_source_type:'county', data_list_type: dataType)
  .knex
  .select('LongName', 'MetadataEntryID')
  .orderBy('MetadataEntryID')
  .then (data) ->
    _.map(data, 'LongName')
  .then (cols) ->
    columns[fileType][action][dataType] = cols


getColumns = (fileType, action, dataType) -> Promise.try () ->
  if !columns[fileType][action][dataType]?
    _getColumnsImpl(fileType, action, dataType)
  else
    columns[fileType][action][dataType]


module.exports = {
  NUM_ROWS_TO_PAGINATE
  BLACKKNIGHT_PROCESS_DATES
  BLACKKNIGHT_COPY_DATES
  TAX
  DEED
  MORTGAGE
  REFRESH
  UPDATE
  NO_NEW_DATA_FOUND
  DELETE
  LOAD
  getColumns
  tableIdMap
  checkDropChain
  queuePerFileSubtasks
  findNewFolders
}
