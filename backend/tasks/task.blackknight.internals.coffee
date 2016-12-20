_ = require 'lodash'
Promise = require "bluebird"
svc = require '../services/service.dataSource'
{HardFail} = require '../utils/errors/util.error.jobQueue'
logger = require('../config/logger').spawn('task:blackknight:internals')
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
keystore = require '../services/service.keystore'
dbs = require '../config/dbs'
awsService = require '../services/service.aws'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
countyHelpers = require './util.countyHelpers'


NUM_ROWS_TO_PAGINATE = 1000
BLACKKNIGHT_PROCESS_INFO = 'blackknight process info'
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
MAX_DATE = 'max date'
DATES_COMPLETED = 'dates completed'
NO_NEW_DATA_FOUND = 'no new data found'
DELETE_BATCH_ID = 'delete batch_id'
DELETED_FIPS = 'deleted all fips data'
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

  result =
    "#{REFRESH}": []
    "#{UPDATE}": []
    "#{DELETE}": []
    fipsMap: {}

  # each Key in Bucket...
  folderPrefix = "Managed_#{config.action}/#{config.tableId}#{config.date}/"
  for item in contents
    fileName = item.Key.substring(folderPrefix.length)

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
      _.merge fileInfo,
        fileType: DELETE
        listType: DELETE
        rawTableSuffix: "#{config.action.slice(0,1)}_DELETES_#{config.date}"

    else if (classified = _isLoad(fileName))
      fips = fileName.slice(0, 5)
      result.fipsMap[fips] = true
      _.merge fileInfo,
        fileType: LOAD
        rawTableSuffix: "#{config.action.slice(0,1)}_#{fips}_#{config.date}"
        normalSubid: fips
        deletes: dataLoadHelpers.DELETE.INDICATED

    if classified
      # apply to appropriate list
      result[fileInfo.listType].push fileInfo

  result


updateProcessInfo = (newProcessInfo) ->
  defaults = {}
  defaults[DATES_QUEUED] = []
  defaults[DATES_COMPLETED] = []
  defaults[FIPS_QUEUED] = []
  defaults[MAX_DATE] = null

  processInfoPromise = keystore.getValuesMap(BLACKKNIGHT_PROCESS_INFO, defaultValues: defaults)
  Promise.join processInfoPromise, (processInfo) ->
    logger.debug () -> "finished processing #{newProcessInfo.date} / #{newProcessInfo.fips_code}"
    logger.debug () -> "old processInfo values: #{JSON.stringify(processInfo)}"

    if newProcessInfo.other_values
      _.extend(processInfo, newProcessInfo.other_values)

    processInfo[DATES_QUEUED] = _.filter(_.uniq(processInfo[DATES_QUEUED]), (v) -> v?).sort()

    Promise.try () ->
      if !newProcessInfo.fips_code?
        # this task was an empty run, no fips stuff to deal with
        return

      # remove the fips code first
      index = processInfo[FIPS_QUEUED].indexOf(newProcessInfo.fips_code)
      if index >= 0
        processInfo[FIPS_QUEUED].splice(index, 1)
      else
        logger.warn "Unable to remove FIPS #{newProcessInfo.fips_code} from [#{processInfo[FIPS_QUEUED]}]"
    .then () ->
      if !newProcessInfo.date || processInfo[FIPS_QUEUED].length > 0
        # if we didn't process a date, or we did and we still have more FIPS codes queued, then don't change the date
        return

      processInfo[CURRENT_PROCESS_DATE] = null
      index = processInfo[DATES_QUEUED].indexOf(newProcessInfo.date)
      if index >= 0
        processInfo[DATES_QUEUED].splice(index, 1)
      else
        logger.warn "Unable to remove date #{newProcessInfo.date} from #{processInfo[DATES_QUEUED]}"
      if processInfo[DATES_COMPLETED].indexOf(newProcessInfo.date) == -1
        processInfo[DATES_COMPLETED].push(newProcessInfo.date)
      else
        logger.warn "Date already marked as completed: #{newProcessInfo.date} in #{processInfo[DATES_COMPLETED]}"
    .then () ->
      keystore.setValuesMap(processInfo, {namespace: BLACKKNIGHT_PROCESS_INFO})

pushProcessingDate = (date) -> Promise.try () ->
  keystore.getValue(DATES_QUEUED, namespace: BLACKKNIGHT_PROCESS_INFO, defaultValue: [])
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
      logger.debug () -> "New blackknight directory found: /Managed_#{action}/#{dir.name}"

      if date < nextFolderSet.date
        nextFolderSet = {date}
      if date == nextFolderSet.date
        nextFolderSet[type] = "/Managed_#{action}/#{dir.name}"
    if nextFolderSet.date == '99999999'
      logger.debug () -> "found no new folders for #{action}"
    return nextFolderSet


# scan and classify (into Load or Delete) file data for processing
getProcessInfo = (subtask, subtaskStartTime) ->
  defaults = {}
  defaults[DATES_QUEUED] = []
  defaults[FIPS_QUEUED] = []
  defaults[CURRENT_PROCESS_DATE] = null
  defaults[DELETE_BATCH_ID] = null
  keystore.getValuesMap(BLACKKNIGHT_PROCESS_INFO, defaultValues: defaults)
  .then (oldProcessInfo) ->
    processInfo =
      hasFiles: false
      startTime: subtaskStartTime
    logger.debug () -> "seeking next processing set from #{JSON.stringify(oldProcessInfo)}"

    # decide whether we just process the next FIPS, or do the special processing that happens when we move to a new date
    if oldProcessInfo[FIPS_QUEUED].length > 0
      processInfo.date = oldProcessInfo[CURRENT_PROCESS_DATE]
      processInfo.fips = oldProcessInfo[FIPS_QUEUED][0]
      processInfo.deleteBatchId = oldProcessInfo[DELETE_BATCH_ID]
      logger.debug () -> "processing date/fips: #{processInfo.date}/#{processInfo.fips}"
    else if oldProcessInfo[DATES_QUEUED].length > 0
      nextDate = _.reduce(oldProcessInfo[DATES_QUEUED], (min, val) -> if !val? || min < val then min else val)
      if oldProcessInfo[MAX_DATE] && nextDate > oldProcessInfo[MAX_DATE]
        logger.debug () -> "next date would be #{nextDate}, GTFO due to maxDate of #{oldProcessInfo[MAX_DATE]}"
        return processInfo
      processInfo.date = nextDate
      logger.debug () -> "processing new date: #{processInfo.date}"
    else
      logger.debug () -> "no dates or fips to process, GTFO"
      return processInfo

    tableIds = Object.keys(tableIdMap)
    Promise.map tableIds, (tableId) ->

      refreshConfig =
        extAcctName: awsService.buckets.BlackknightData
        Prefix: "Managed_#{REFRESH}/#{tableId}#{processInfo.date}"
      updateConfig =
        extAcctName: awsService.buckets.BlackknightData
        Prefix: "Managed_#{UPDATE}/#{tableId}#{processInfo.date}"
      if processInfo.fips
        refreshConfig.Prefix += "/#{processInfo.fips}"
        updateConfig.Prefix += "/#{processInfo.fips}"

      # pull sets of filtered (and classified as `Load` or `Delete`) keys
      refreshPromise = awsService.listObjects(refreshConfig)
      .then (refreshResponse) ->
        _filterS3Contents(refreshResponse.Contents, {action: REFRESH, tableId, date: processInfo.date, startTime: subtaskStartTime})

      updatePromise = awsService.listObjects(updateConfig)
      .then (updateResponse) ->
        _filterS3Contents(updateResponse.Contents, {action: UPDATE, tableId, date: processInfo.date, startTime: subtaskStartTime})

      # combine the Update and Refresh lists (both filter processes may yield some `Delete` items)
      Promise.join refreshPromise, updatePromise, (refreshInfo, updateInfo) ->
        "#{REFRESH}": refreshInfo[REFRESH]
        "#{UPDATE}": updateInfo[UPDATE]
        "#{DELETE}": refreshInfo[DELETE].concat(updateInfo[DELETE])
        fipsMap: _.extend(refreshInfo.fipsMap, updateInfo.fipsMap)

    # combine info from all tableIds
    .then ([table1, table2, table3]) ->
      # combine lists
      processInfo[REFRESH] = table1[REFRESH].concat(table2[REFRESH], table3[REFRESH])
      processInfo[UPDATE] = table1[UPDATE].concat(table2[UPDATE], table3[UPDATE])
      processInfo[DELETE] = table1[DELETE].concat(table2[DELETE], table3[DELETE])

      if !processInfo[REFRESH].length && !processInfo[UPDATE].length && !processInfo[DELETE].length
        return processInfo

      processInfo.hasFiles = true
      # check if we are processing the next FIPS for a date we already started
      if processInfo.fips?
        processInfo.loadDeleteFiles = false
        processInfo[DELETE] = []
        for action in [REFRESH, UPDATE]
          for dataType in [TAX, DEED, MORTGAGE]
            # need to force re-processing of the raw delete data so we can delete for the current FIPS
            if dataType == TAX && action == REFRESH
              # we need to skip this, because we're not keeping historical tax records and so we manage our own tax
              # refresh deletes as part of the loadRawData subtask for the refresh data
              continue
            processInfo[DELETE].push
              action: action
              dataType: dataType
              fips_code: processInfo.fips
              rawDeleteBatchId: processInfo.deleteBatchId
              rawTableSuffix: "#{action.slice(0,1)}_DELETES_#{processInfo.date}"
        return processInfo

      # from here on, we're handling special logic for when we didn't know what FIPS we were processing ahead of time
      # (i.e. we've started on a new date, and so need to load the delete files and queue the available FIPS codes)
      fipsMap = _.extend(table1.fipsMap, table2.fipsMap, table3.fipsMap)
      processInfo.fipsQueue = _.keys(fipsMap).sort()
      if Array.isArray(subtask.data?.fipsCodes)
        processInfo.fipsQueue = _.intersection(processInfo.fipsQueue, subtask.data.fipsCodes)
      else if subtask.data?.fipsCodes
        processInfo.fipsQueue = _.filter processInfo.fipsQueue, (fips) ->
          (new RegExp(subtask.data.fipsCodes)).test(fips)
      processInfo.fips = processInfo.fipsQueue[0]
      processInfo[REFRESH] = _.filter(processInfo[REFRESH], 'normalSubid', processInfo.fips)
      processInfo[UPDATE] = _.filter(processInfo[UPDATE], 'normalSubid', processInfo.fips)
      processInfo.deleteBatchId = subtask.batch_id
      processInfo.loadDeleteFiles = true
      processInfo


# divvy out the file data (in `processInfo`) we found into procs that process that data (parallelized)
useProcessInfo = (subtask, processInfo) ->
  logger.debug () -> "useProcessInfo: #{JSON.stringify(processInfo,null,2)}"
  newProcessInfo =
    date: processInfo.date
    fips_code: processInfo.fips
  if processInfo.loadDeleteFiles
    newProcessInfo.other_values =
      "#{FIPS_QUEUED}": processInfo.fipsQueue
      "#{DELETE_BATCH_ID}": subtask.batch_id
      "#{CURRENT_PROCESS_DATE}": processInfo.date
  dbs.transaction 'main', (transaction) ->
    dates = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: 'cleanup', manualData: newProcessInfo, replace: true})
    if !processInfo.hasFiles || !processInfo.fips
      return dates

    keystore.setValue(DELETED_FIPS, false, {namespace: BLACKKNIGHT_PROCESS_INFO, transaction})
    .then () ->
      # initiate processing and loading for each list with concurrency
      deletes = _queuePerFileSubtasks(transaction, subtask, processInfo, DELETE)
      refresh = _queuePerFileSubtasks(transaction, subtask, processInfo, REFRESH)
      update = _queuePerFileSubtasks(transaction, subtask, processInfo, UPDATE)
      access = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "waitForExclusiveAccess"})
      activateData =
        startTime: processInfo.startTime
        subset: fips_code: processInfo.fips
      activate = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "activateNewData", manualData: activateData, replace: true})
      # ensure normalized data tables exist -- need all 3 no matter what types we have data for
      taxTable = countyHelpers.ensureNormalizedTable(TAX, processInfo.fips)
      deedTable = countyHelpers.ensureNormalizedTable(DEED, processInfo.fips)
      mortTable = countyHelpers.ensureNormalizedTable(MORTGAGE, processInfo.fips)
      Promise.join(refresh, update, deletes, access, activate, dates, taxTable, deedTable, mortTable)


_queuePerFileSubtasks = (transaction, subtask, processInfo, action) -> Promise.try () ->
  if !processInfo[action]?.length
    return

  if action != DELETE
    loadRawDataPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "loadRawData", manualData: processInfo[action], replace: true})
    recordChangeCountsPromise = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "recordChangeCounts", manualData: processInfo[action], replace: true, concurrency: 80})
    return Promise.join(loadRawDataPromise, recordChangeCountsPromise)

  if processInfo.loadDeleteFiles
    for fileData in processInfo[DELETE]
      fileData.fips_code = processInfo.fips
    return jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: "loadRawData", manualData: processInfo[DELETE], replace: true})

  # skip the load subtask, because we're piggybacking on a load that happened alongside a prior fips code
  # this means we have to count the number of relevant rows in those tables
  numRowsToPage = subtask.data?.numRowsToPageDelete || NUM_ROWS_TO_PAGINATE

  Promise.map processInfo[DELETE], (mergeData) ->
    fauxSubtask = _.extend({}, subtask, data: mergeData)
    dbFn = tables.temp(subid: dataLoadHelpers.buildUniqueSubtaskName(fauxSubtask, mergeData.rawDeleteBatchId))
    sqlHelpers.checkTableExists(dbFn)
    .then (exists) ->
      if !exists
        return 0
      dbFn
      .count('*')
      .then (count) ->
        count?[0]?.count
    .then (numRows) ->
      if !numRows
        return
      jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRows, maxPage: numRowsToPage, laterSubtaskName: 'deleteData', mergeData})


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
  MAX_DATE
  CURRENT_PROCESS_DATE
  DATES_COMPLETED
  DELETE
  LOAD
  DELETE_BATCH_ID
  DELETED_FIPS

  getColumns
  findNextFolderSet

  updateProcessInfo
  pushProcessingDate
  getProcessInfo
  useProcessInfo
}
