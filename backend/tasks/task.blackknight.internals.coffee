_ = require 'lodash'
Promise = require "bluebird"
svc = require '../services/service.dataSource'
{HardFail} = require '../utils/errors/util.error.jobQueue'
logger = require('../config/logger').spawn('task:blackknight:internals')
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
keystore = require '../services/service.keystore'
moment = require 'moment'
dbs = require '../config/dbs'
awsService = require '../services/service.aws'


NUM_ROWS_TO_PAGINATE = 1000
BLACKKNIGHT_PROCESS_INFO = 'blackknight process info'
BLACKKNIGHT_PROCESS_DATES_FINISHED = 'blackknight process dates finished'
BLACKKNIGHT_COPY_INFO = 'blackknight copy info'
TAX = 'tax'
DEED = 'deed'
MORTGAGE = 'mortgage'
REFRESH = 'Refresh'
UPDATE = 'Update'
DATES_QUEUED = 'dates queued'
FIPS_QUEUED = 'fips queued'
CURRENT_PROCESS_DATE = 'current process date'
LAST_COMPLETED_DATE = 'last completed date'
DATES_COMPLETED = 'dates completed'
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
# some classifiers for _filterS3Contents
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
    return true
  return false


# Filter s3, classify as data to DELETE or LOAD based on filename
_filterS3Contents = (contents, config) -> Promise.try () ->
  # required params, mostly for going ahead and populating the "fileInfo" objects used later
  if !("action" of config && "tableId" of config && "date" of config && "startTime" of config)
    throw new HardFail("S3 filtering requires config parameters: `action`, `date`, `tableId`, and `startTime`")

  filtered =
    "#{REFRESH}": []
    "#{UPDATE}": []
    "#{DELETE}": []

  # this is defensive: this will be null if no dates were available for processing (default) if for some reason we get here
  if !config.date?
    return filtered

  # each Key in Bucket...
  for item in contents
    folderPrefix = "Managed_#{config.action}/#{config.tableId}#{config.date}/"
    fileName = item.Key.replace(folderPrefix, '')

    classified = false
    fileInfo =
      action: config.action                # 'Refresh' | 'Update'             # does NOT include 'Delete'
      listType: config.action              # 'Refresh' | 'Update' | 'Delete'  # includes 'Delete'
      date: config.date
      path: folderPrefix
      fileName: fileName
      fileType: null                       # 'Delete' | 'Load'
      startTime: config.startTime
      dataType: tableIdMap[config.tableId] # 'tax' | 'deed' | 'mortgage'


    if (classified = _isDelete(fileName))
      date = fileName.slice(-12, -4)
      _.merge fileInfo,
        fileType: DELETE
        listType: DELETE
        rawTableSuffix: "#{config.action.slice(0,1)}_DELETES_#{date}"

    else if (classified = _isLoad(fileName))
      fips = fileName.slice(0, 5)
      # TODO: remove when we turn on all FIPS codes
      if fips != '12021' && fips != '12099'
        classified = false
      else
        date = fileName.slice(-15, -7)
        _.merge fileInfo,
          fileType: LOAD
          rawTableSuffix: "#{config.action.slice(0,1)}_#{fips}_#{date}"
          normalSubid: fips
          indicateDeletes: (config.action == REFRESH)
          deletes: dataLoadHelpers.DELETE.INDICATED

    if classified
      # apply to appropriate list
      filtered[fileInfo.listType].push fileInfo
  filtered

#
# timestamp / processing date queue maintenance
#
nextProcessingSet = () ->
  defaults = {}
  defaults[DATES_QUEUED] = []
  defaults[FIPS_QUEUED] = []
  keystore.getValue(BLACKKNIGHT_PROCESS_INFO, defaultValues: defaults)
  .then (processInfo) ->
    logger.debug () -> "seeking next date from #{JSON.stringify(datesQueued)}"
    result =
      nextDate: processInfo[DATES_QUEUED].sort().shift() || null
      nextFips: processInfo[FIPS_QUEUED].sort().shift() || null
    return result

popProcessingDates = (dates) ->
  defaults = {}
  defaults[DATES_QUEUED] = []
  defaults[DATES_COMPLETED] = []

  processInfoPromise = keystore.getValuesMap(BLACKKNIGHT_PROCESS_INFO, defaultValues: defaults)
  Promise.join processInfoPromise, (processInfo) ->
    logger.debug () -> "moving #{JSON.stringify(dates)}"
    logger.debug () -> "from #{DATES_QUEUED}"
    logger.debug () -> "to #{DATES_COMPLETED}"
    logger.debug () -> "in #{JSON.stringify(processInfo)}"
    processInfo[DATES_QUEUED] = _.uniq(processInfo[REFRESH]).sort()

    # simply remove the given "dates" if exists, otherwise pull the 0th element (since sorted)
    if dates?
      refreshIndex = processInfo[REFRESH].indexOf(dates[REFRESH])
      updateIndex = processInfo[UPDATE].indexOf(dates[UPDATE])
    else
      refreshIndex = 0
      updateIndex = 0

    if refreshIndex >= 0 && ([refreshItem] = processInfo[REFRESH].splice(refreshIndex, 1))
      processDates[REFRESH] = refreshItem
      if finishedDateQueue[REFRESH].indexOf(refreshItem) == -1
        finishedDateQueue[REFRESH].push(refreshItem)

    if updateIndex >= 0 && ([updateItem] = processInfo[UPDATE].splice(updateIndex, 1))
      processDates[UPDATE] = updateItem
      if finishedDateQueue[UPDATE].indexOf(updateItem) == -1
        finishedDateQueue[UPDATE].push(updateItem)

    dbs.transaction (transaction) ->
      keystore.setValuesMap(processInfo, {namespace: BLACKKNIGHT_PROCESS_INFO, transaction})
      .then () ->
        keystore.setValuesMap(finishedDateQueue, {namespace: BLACKKNIGHT_PROCESS_DATES_FINISHED, transaction})
    .then () ->
      return processDates

pushProcessingDate = (date) -> Promise.try () ->
  keystore.getValue(DATES_QUEUED, namespace: BLACKKNIGHT_PROCESS_INFO, defaultValues: defaults)
  .then (datesQueued) ->
    logger.debug () -> "pushing #{JSON.stringify(date)}"
    logger.debug () -> "to #{JSON.stringify(datesQueued)}"

    # avoid adding dupes
    if _.includes(datesQueued, date)
      logger.warn("Processed date has already been queued: #{date}.")
    else
      datesQueued.push(date)

    keystore.setValue(DATES_QUEUED, datesQueued, namespace: BLACKKNIGHT_PROCESS_INFO)


#
# helpers for organizing, classifying, and processing files to process
#
findNextFolderSet = (ftp, action, copyDate) -> Promise.try () ->
  ftp.list("/Managed_#{action}")
  .then (rootListing) ->

    nextFolderSet = {date: '99999999'}
    for dir in rootListing when dir.type == 'd'
      date = dir.name.slice(-8)
      type = tableIdMap[dir.name.slice(0, -8)]
      if !type
        logger.warn("Unexpected directory found in blackknight FTP drop: /Managed_#{action}/#{dir.name}")
        continue
      if copyDate >= date
        continue
      logger.info("New blackknight directory found: /Managed_#{action}/#{dir.name}")

      if date < nextFolderSet.date
        nextFolderSet = {date}
      nextFolderSet[type] = "/Managed_#{action}/#{dir.name}"
    if nextFolderSet.date == '99999999'
      logger.debug () -> "found no new folders for #{action}"
      return null
    return nextFolderSet


# scan and classify (into Load or Delete) file data for processing
getProcessInfo = (subtask, subtaskStartTime) ->
  # per date, filter and classify files as `Load` or `Delete`
  nextProcessingSet()
  .then (processDates) ->
    logger.debug () -> "processDates: #{JSON.stringify(processDates)}"
    processInfo =
      dates: processDates
      hasFiles: false
      startTime: subtaskStartTime
    processInfo[REFRESH] = []
    processInfo[UPDATE] = []
    processInfo[DELETE] = []

    tableIds = Object.keys(tableIdMap)
    Promise.map tableIds, (tableId) ->

      refreshConfig =
        extAcctName: awsService.buckets.BlackknightData
        Prefix: "Managed_#{REFRESH}/#{tableId}#{processDates.Refresh}"
      updateConfig =
        extAcctName: awsService.buckets.BlackknightData
        Prefix: "Managed_#{UPDATE}/#{tableId}#{processDates.Update}"

      # pull sets of filtered (and classified as `Load` or `Delete`) keys
      refreshPromise = awsService.listObjects(refreshConfig)
      .then (refreshResponse) ->
        _filterS3Contents(refreshResponse.Contents, {action: REFRESH, tableId, date: processDates.Refresh, startTime: subtaskStartTime})

      updatePromise = awsService.listObjects(updateConfig)
      .then (updateResponse) ->
        _filterS3Contents(updateResponse.Contents, {action: UPDATE, tableId, date: processDates.Update, startTime: subtaskStartTime})

      # combine the Update and Refresh lists (both filter processes may yield some `Delete` items)
      Promise.join(refreshPromise, updatePromise)
      .then ([refreshInfo, updateInfo]) ->
        {
          "#{REFRESH}": refreshInfo[REFRESH]
          "#{UPDATE}": updateInfo[UPDATE]
          "#{DELETE}": refreshInfo[DELETE].concat updateInfo[DELETE]
        }

    # combine lists of all tableIds
    .then ([table1, table2, table3]) ->
      list = [table1, table2, table3]

      # combine lists (union is helpful here for combining lists, not necessarily needing the non-dupe consequence)
      processInfo[REFRESH] = _.union table1[REFRESH], table2[REFRESH], table3[REFRESH]
      processInfo[UPDATE] = _.union table1[UPDATE], table2[UPDATE], table3[UPDATE]
      processInfo[DELETE] = _.union table1[DELETE], table2[DELETE], table3[DELETE]

      if (processInfo[REFRESH].length + processInfo[UPDATE].length + processInfo[DELETE].length) > 0
        processInfo.hasFiles = true

      logger.debug () -> "compiled `processInfo`: #{JSON.stringify(processInfo)}"

      return processInfo


# divvy out the file data (in `processInfo`) we found into procs that process that data (parallelized)
useProcessInfo = (subtask, processInfo) ->
  dbs.transaction 'main', (transaction) ->
    if processInfo.hasFiles

      # initiate processing and loading for each list with concurrency
      deletes = queuePerFileSubtasks(transaction, subtask, processInfo[DELETE], DELETE)
      refresh = queuePerFileSubtasks(transaction, subtask, processInfo[REFRESH], REFRESH)
      update = queuePerFileSubtasks(transaction, subtask, processInfo[UPDATE], UPDATE)
      activate = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "activateNewData", manualData: {deletes: dataLoadHelpers.DELETE.INDICATED, startTime: processInfo.startTime}, replace: true})
      fileProcessing = Promise.join refresh, update, deletes, activate, (refreshFips, updateFips) ->

        # keep track of fips
        fipsCodes = _.extend(refreshFips, updateFips)
        normalizedTablePromises = []
        for fipsCode of fipsCodes
          # ensure normalized data tables exist -- need all 3 no matter what types we have data for
          normalizedTablePromises.push dataLoadHelpers.ensureNormalizedTable(TAX, fipsCode)
          normalizedTablePromises.push dataLoadHelpers.ensureNormalizedTable(DEED, fipsCode)
          normalizedTablePromises.push dataLoadHelpers.ensureNormalizedTable(MORTGAGE, fipsCode)
        Promise.all(normalizedTablePromises)
    else
      fileProcessing = Promise.resolve()
    dates = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: 'saveProcessDates', manualData: {dates: processInfo.dates}, replace: true})
    Promise.join fileProcessing, dates, () ->  # empty handler


queuePerFileSubtasks = (transaction, subtask, files, action) -> Promise.try () ->
  if !files?.length
    return

  fipsCodes = {}
  if action == DELETE
    filesForCounts = []
  else
    filesForCounts = files
    for el in files
      fipsCodes[el.normalSubid] = true

  # load task
  loadRawDataPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "loadRawData", manualData: files, replace: true})

  # non-delete `changeCounts` takes no data
  recordChangeCountsPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "recordChangeCounts", manualData: filesForCounts, replace: true, concurrency: 80})

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
  BLACKKNIGHT_PROCESS_INFO
  BLACKKNIGHT_COPY_INFO
  TAX
  DEED
  MORTGAGE
  REFRESH
  UPDATE
  DATES_QUEUED
  FIPS_QUEUED
  NO_NEW_DATA_FOUND
  LAST_COMPLETED_DATE
  CURRENT_PROCESS_DATE
  DATES_COMPLETED
  DELETE
  LOAD

  getColumns
  tableIdMap
  queuePerFileSubtasks
  findNextFolderSet

  nextProcessingSet
  popProcessingDates
  pushProcessingDate
  getProcessInfo
  useProcessInfo
}
