Promise = require "bluebird"
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../util.jobQueue'
tables = require '../../config/tables'
logger = require '../../config/logger'
sqlHelpers = require '../util.sql.helpers'
coreLogicHelpers = require './util.coreLogicHelpers'
encryptor = require '../../config/encryptor'
PromiseFtp = require '../util.promiseFtp'
_ = require 'lodash'
keystore = require '../../services/service.keystore'
TaskImplementation = require './util.taskImplementation'


NUM_ROWS_TO_PAGINATE = 500
CORELOGIC_PROCESS_DATES = 'corelogic process dates'
TAX = 'tax'
DEED = 'deed'


checkFtpDrop = (subtask) ->
  ftp = new PromiseFtp()
  connectPromise = ftp.connect
    host: subtask.task_data.host
    user: subtask.task_data.user
    password: encryptor.decrypt(subtask.task_data.password)
  .then () ->
    ftp.list('/')
  defaultValues = {}
  defaultValues[TAX] = '19700101'
  defaultValues[DEED] = '19700101'
  processDatesPromise = keystore.propertyDb.getValuesMap CORELOGIC_PROCESS_DATES, defaultValues: defaultValues
  Promise.join connectPromise, processDatesPromise, (rootListing, processDates) ->
    todo = {}
    for dir in _.sortBy(rootListing, 'name') when dir.type == 'd' then do (dir) ->
      date = dir.name.slice(0, 8)
      type = dir.name.slice(8).toLowerCase()
      if type == 'deeds'
        type = DEED
      if !processDates[type]?
        logger.warn("Unexpected directory found in corelogic FTP drop: #{dir.name}")
        return
      if processDates[type] >= date
        return
      if type == TAX
        # tax drops are full dumps, so ignore all but the last
        todo[TAX] = dir.name
      else  # type == DEED
        # deed files are incremental updates, so we need the earliest unprocessed drop
        if !todo[DEED]?
          todo[DEED] = dir.name
    if _.isEmpty(todo)
      logger.debug "No new corelogic directories to process"
      return ftp.end()
    dates = {}
    if todo[TAX]?
      # ##################################### TODO: debugging, remove this when done coding the corelogic task
      todo[TAX] = '20140919Tax'  ############ TODO: debugging, remove this when done coding the corelogic task
      # ##################################### TODO: debugging, remove this when done coding the corelogic task
      logger.debug "Found new corelogic tax directory to process: #{todo[TAX]}"
      dates[TAX] = todo[TAX].slice(0, 8)
      taxFilesPromise = ftp.list("/#{todo[TAX]}")
    else
      taxFilesPromise = Promise.resolve()
    if todo[DEED]?
      logger.debug "Found new corelogic deed directory to process: #{todo[DEED]}"
      dates[DEED] = todo[DEED].slice(0, 8)
      deedFilesPromise = ftp.list("/#{todo[DEED]}")
    else
      deedFilesPromise = Promise.resolve()
    Promise.join taxFilesPromise, deedFilesPromise, (taxFiles, deedFiles) ->
      ftpEnd = ftp.end()
      # this transaction is important because we don't want the subtasks enqueued below to start showing up as available
      # on their queue out-of-order; normally, subtasks enqueued by another subtask won't be considered as available
      # until the current subtask finishes, but the checkFtpDrop subtask is on a different queue than those being
      # enqueued, and that messes with it.  We could probably fix that edge case, but it would have a steep performance
      # cost, so instead I left it as a caveat to be handled manually (like this) the few times it arises
      jobQueue.transaction (transaction) ->
        taxSubtasks = _queuePerFileSubtasks(transaction, subtask, todo[TAX], TAX, taxFiles)
        deedSubtasks = _queuePerFileSubtasks(transaction, subtask, todo[DEED], DEED, deedFiles)
        finalizePrep = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_finalizeDataPrep", null, true)
        activate = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_activateNewData", {deleteUntouchedRows: dates[TAX]?}, true)
        dates = jobQueue.queueSubsequentSubtask(transaction, subtask, 'corelogic_saveProcessDates', dates: dates, true)
        Promise.join ftpEnd, taxSubtasks, deedSubtasks, finalizePrep, activate, dates, () ->  # empty handler

_queuePerFileSubtasks = (transaction, subtask, dir, type, files) -> Promise.try () ->
  if !files?.length
    return
  loadDataList = []
  countDataList = []
  for file in files when file.name.endsWith('.zip')
    rawTableSuffix = "#{type}_#{file.name.slice(0, -4)}"
    loadDataList.push
      path: "/#{dir}/#{file.name}"
      rawTableSuffix: rawTableSuffix
      type: type
    countDataList.push
      rawTableSuffix: rawTableSuffix
      type: type
      markOtherRowsDeleted: (type == TAX)  # tax data is full-dump, deed data is incremental
  loadRawDataPromise = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_loadRawData", loadDataList, true)
  recordChangeCountsPromise = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_recordChangeCounts", countDataList, true)
  Promise.join loadRawDataPromise, recordChangeCountsPromise, () ->  # empty handler

loadRawData = (subtask) ->
  coreLogicHelpers.loadRawData subtask,
    rawTableSuffix: subtask.data.rawTableSuffix
    dataSourceId: 'corelogic'
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask null, subtask, numRows, NUM_ROWS_TO_PAGINATE, "corelogic_normalizeData",
      rawTableSuffix: subtask.data.rawTableSuffix
      type: subtask.data.type

saveProcessedDates = (subtask) ->
  keystore.propertyDb.setValuesMap(subtask.data.dates, namespace: CORELOGIC_PROCESS_DATES)
    
normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    rawTableSuffix: subtask.data.rawTableSuffix
    dataSourceId: 'corelogic'
    dataSourceType: 'county'
    updateRecord: coreLogicHelpers.updateRecord

finalizeDataPrep = (subtask) ->
  tables.propertyData.listing()
  .distinct('rm_property_id')
  .select()
  .where(batch_id: subtask.batch_id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, _.pluck(ids, 'rm_property_id'), NUM_ROWS_TO_PAGINATE, "corelogic_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, coreLogicHelpers.finalizeData.bind(null, subtask)


module.exports = new TaskImplementation
  checkFtpDrop: checkFtpDrop
  loadRawData: loadRawData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts.bind(null, 'main', tables.propertyData.listing)
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData
