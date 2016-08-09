_ = require 'lodash'
Promise = require "bluebird"
svc = require '../services/service.dataSource'
{HardFail} = require '../utils/errors/util.error.jobQueue'
logger = require('../config/logger').spawn('task:blackknight:internals')
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
keystore = require '../services/service.keystore'
moment = require 'moment'


RESTRICT_TO_FIPS = ['12021']
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


#
# some classifiers for fitlerS3Contents
#
_isDelete = (fileName) ->
  if fileName.endsWith('.txt')
    if fileName.startsWith('metadata_')   #ignore `metadata_*.txt`
      return false
    if fileName.indexOf('_Delete_') == -1 # require `_Delete_` as part of fileName
      logger.warn("Unexpected fileName found in bucket for Delete: #{fileName}")
      return false
    return true
  return false

_isLoad = (fileName) ->
  if fileName.endsWith('.gz')
    if RESTRICT_TO_FIPS.length > 0
      fips = fileName.slice(0, 5)
      if !_.includes(RESTRICT_TO_FIPS, fips)
        logger.warn("Ignoring file due to FIPS code: #{fips}")
        return false
    return true
  return false



# Filter s3, classify as data to DELETE or LOAD based on filename
filterS3Contents = (contents, config) -> Promise.try () ->
  console.log "filterS3Contents(), REFRESH: #{REFRESH}"
  if !("action" of config && "tableId" of config && "date" of config && "startTime" of config)
    throw new HardFail("S3 filtering requires config parameters: `action`, `date`, `tableId`, and `startTime`")
  # console.log "\n####################################################################################################################################"
  # console.log "filterFiles()"
  # console.log "-------config-------:\n#{JSON.stringify(config,null,2)}"

  filtered =
    "#{REFRESH}": []
    "#{UPDATE}": []
    "#{DELETE}": []

  for item in contents
    # console.log "item:\n#{JSON.stringify(item,null,2)}"
    folderPrefix = "Managed_#{config.action}/#{config.tableId}#{config.date}/"
    fileName = item.Key.replace(folderPrefix, '')
    classified = false
    fileInfo =
      action: config.action          # 'Refresh' | 'Update'             # does NOT include 'Delete'
      listType: config.action        # 'Refresh' | 'Update' | 'Delete'  # includes 'Delete'
      date: config.date
      path: item.Key
      fileName: fileName
      fileType: null                 # 'Delete' | 'Load'
      startTime: config.startTime
      dataType: tableIdMap[config.tableId] # 'tax' | 'deed' | 'mortgage'

    # console.log "Key: #{item.Key}"

    if (classified = _isDelete(fileName))
      _.merge fileInfo,
        fileType: DELETE
        listType: DELETE
        rawTableSuffix: "#{fileName.slice(0, -4)}"

    else if (classified = _isLoad(fileName))
      console.log "REFRESH: #{REFRESH}"
      _.merge fileInfo,
        fileType: LOAD
        rawTableSuffix: fileName.slice(0, -7)
        normalSubid: fileName.slice(0, 5)
        indicateDeletes: (config.action == REFRESH)
        deletes: dataLoadHelpers.DELETE.INDICATED

    if classified
      # apply to appropriate list
      filtered[fileInfo.listType].push fileInfo
      # console.log "pushed:\n#{JSON.stringify(fileInfo,null,2)}"
    
  filtered


nextProcessingDates = () ->
  defaults = {}
  defaults[REFRESH] = []
  defaults[UPDATE] = []

  keystore.getValuesMap(BLACKKNIGHT_PROCESS_DATES, defaultValues: defaults)
  .then (currentDateQueue) ->
    currentDateQueue[REFRESH].sort()
    currentDateQueue[UPDATE].sort()
    console.log "nextProcessingDates()"
    console.log "currentDateQueue:\n#{JSON.stringify(currentDateQueue)}"
    processDates =
      "#{REFRESH}": null
      "#{UPDATE}": null

    if (refreshItem = currentDateQueue[REFRESH].shift())
      processDates[REFRESH] = refreshItem

    if (updateItem = currentDateQueue[UPDATE].shift())
      processDates[UPDATE] = updateItem

    processDates

popProcessingDates = (dates) ->
  defaults = {}
  defaults[REFRESH] = []
  defaults[UPDATE] = []

  keystore.getValuesMap(BLACKKNIGHT_PROCESS_DATES, defaultValues: defaults)
  .then (currentDateQueue) ->
    currentDateQueue[REFRESH].sort()
    currentDateQueue[UPDATE].sort()

    processDates =
      "#{REFRESH}": null
      "#{UPDATE}": null

    if dates?
      refreshIndex = currentDateQueue[REFRESH].indexOf(dates[REFRESH])
      updateIndex = currentDateQueue[UPDATE].indexOf(dates[UPDATE])
    else
      refreshIndex = currentDateQueue[REFRESH].length - 1
      updateIndex = currentDateQueue[UPDATE].length - 1

    if refreshIndex >= 0 && (refreshItem = currentDateQueue[REFRESH].splice(refreshIndex, 1))
      processDates[REFRESH] = refreshItem[0]

    if updateIndex >= 0 && (updateItem = currentDateQueue[UPDATE].splice(updateIndex, 1))
      processDates[UPDATE] = updateItem[0]

    keystore.setValuesMap(currentDateQueue, namespace: BLACKKNIGHT_PROCESS_DATES)
    .then () ->
      console.log "popProcessingDates()"
      console.log "returning processDates:\n#{JSON.stringify(processDates,null,2)}"
      console.log "saved currentDateQueue:\n#{JSON.stringify(currentDateQueue,null,2)}"
      return processDates


pushProcessingDates = (dates) -> Promise.try () ->
  defaults = {}
  defaults[REFRESH] = []
  defaults[UPDATE] = []
  keystore.getValuesMap(BLACKKNIGHT_PROCESS_DATES, defaultValues: defaults)
  .then (currentDateQueue) ->
    currentDateQueue[REFRESH].unshift dates[REFRESH]
    currentDateQueue[UPDATE].unshift dates[UPDATE]

    console.log "pushProcessingDates()"
    console.log "dates:\n#{JSON.stringify(dates,null,2)}"
    console.log "currentDateQueue:\n#{JSON.stringify(currentDateQueue)}"
    # `.unshift` compliments `.pop` for queue
    keystore.setValuesMap(currentDateQueue, namespace: BLACKKNIGHT_PROCESS_DATES)


# deprecated
findNewFolders = (ftp, action, processDates, newFolders={}) -> Promise.try () ->
  console.log "\n####################################################################################################################################"
  console.log "findNewFolders()"
  ftp.list("/Managed_#{action}")
  .then (rootListing) ->
    console.log "rootListing:\n#{JSON.stringify(rootListing,null,2)}"
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
      #logger.info("New blackknight directory found: #{newFolders[date+'_'+action][type].path}")
    console.log "newFolders:\n#{JSON.stringify(newFolders,null,2)}"
    newFolders


# deprecated
_checkFolder = (ftp, folderInfo, processLists) -> Promise.try () ->
  #logger.debug "Processing blackknight folder: #{folderInfo.path}"
  ftp.list(folderInfo.path)
  .then (folderListing) ->
    for file in folderListing
      console.log "###### file.name: #{file.name}, file.size: #{file.size}"
      if file.name.endsWith('.txt')
        if file.name.startsWith('metadata_')  #ignore `metadata_*_.txt`
          console.log "starts with `metadata_`, bypassing..."
          continue
        if file.name.indexOf('_Delete_') == -1
          logger.warn("Unexpected file found in blackknight FTP drop: #{folderInfo.path}/#{file.name}")
          continue
        if file.size == 0   #ignore empty file
          console.log "size is 0, bypassing..."
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
      console.log "###### pushing to #{fileType}, fileInfo:\n#{JSON.stringify(fileInfo,null,2)}"
      processLists[fileType].push(fileInfo)


# deprecated
checkDropChain = (ftp, processInfo, newFolders, drops, i) -> Promise.try () ->
  console.log "\n####################################################################################################################################"
  console.log "checkDropChain()"
  console.log "-------processInfo-------:\n#{JSON.stringify(processInfo,null,2)}"
  console.log "-------newFolders.20160405_Refresh-------:\n#{JSON.stringify(newFolders["20160405_Refresh"],null,2)}"
  #console.log "-------drops-------:\n#{JSON.stringify(drops,null,2)}"
  console.log "-------i-------:\n#{i}"

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
    console.log "finished processing, returning processInfo:\n#{JSON.stringify(processInfo,null,2)}"
    processInfo


queuePerFileSubtasks = (transaction, subtask, files, action) -> Promise.try () ->
  console.log "\n####################################################################################################################################"
  console.log "queuePerFileSubtasks()"
  console.log "-------files-------:\n#{JSON.stringify(files,null,2)}"
  console.log "-------action-------:\n#{action}"
  if !files?.length
    return
  # loadDataList = []
  # countDataList = []

  fipsCodes = {}
  # for file in files
  #   loadData =
  #     path: "#{file.path}/#{file.name}"
  #     dataType: file.type
  #     action: file.action
  #   if action == DELETE
  #     loadData.fileType = DELETE
  #     loadData.rawTableSuffix = "#{file.name.slice(0, -4)}"
  #   else
  #     loadData.fileType = LOAD
  #     loadData.rawTableSuffix = "#{file.name.slice(0, -7)}"
  #     loadData.normalSubid = file.name.slice(0, 5)
  #     loadData.startTime = now
  #     fipsCodes[loadData.normalSubid] = true
  #     countDataList.push
  #       rawTableSuffix: loadData.rawTableSuffix
  #       normalSubid: loadData.normalSubid
  #       dataType: file.type
  #       deletes: dataLoadHelpers.DELETE.INDICATED
  #       action: action
  #       indicateDeletes: (action == REFRESH)  # only set this flag for refreshes, not updates
  #   loadDataList.push(loadData)

  loadRawDataPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "loadRawData", manualData: files, replace: true, concurrency: 10})

  # non-delete `changeCounts` takes no data
  filesForDelete = if action == DELETE then files else []
  recordChangeCountsPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "recordChangeCounts", manualData: filesForDelete, replace: true})

  console.log "//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////"
  console.log "queuing (laterSubtaskName): loadRawData, with  (action == #{action})"
  console.log "subtask:\n#{JSON.stringify(subtask,null,2)}"
  console.log "files:\n#{JSON.stringify(files,null,2)}"
  # loadRawDataPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "loadRawData", manualData: loadDataList, replace: true, concurrency: 10})
  # recordChangeCountsPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "recordChangeCounts", manualData: countDataList, replace: true})
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

  filterS3Contents
  nextProcessingDates
  popProcessingDates
  pushProcessingDates
}
