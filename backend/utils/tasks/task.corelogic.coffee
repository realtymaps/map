Promise = require "bluebird"
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../util.jobQueue'
tables = require '../../config/tables'
logger = require '../../config/logger'
sqlHelpers = require '../util.sql.helpers'
countyHelpers = require './util.countyHelpers'
externalAccounts = require '../../services/service.externalAccounts'
PromiseFtp = require 'promise-ftp'
_ = require 'lodash'
keystore = require '../../services/service.keystore'
TaskImplementation = require './util.taskImplementation'
dbs = require '../../config/dbs'


NUM_ROWS_TO_PAGINATE = 5000
CORELOGIC_PROCESS_DATES = 'corelogic process dates'
TAX = 'tax'
DEED = 'deed'


checkFtpDrop = (subtask) ->
  ftp = new PromiseFtp()
  connectPromise = externalAccounts.getAccountInfo('corelogic')
  .then (accountInfo) ->
    ftp.connect
      host: accountInfo.url
      user: accountInfo.username
      password: accountInfo.password
      autoReconnect: true
  .then () ->
    ftp.list('/')
  defaultValues = {}
  defaultValues[TAX] = '19700101'
  defaultValues[DEED] = '19700101'
  processDatesPromise = keystore.getValuesMap(CORELOGIC_PROCESS_DATES, defaultValues: defaultValues)
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
      deletes = dataLoadHelpers.DELETE.UNTOUCHED
    else
      deletes = dataLoadHelpers.DELETE.NONE
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
      dbs.get('main').transaction (transaction) ->
        taxSubtasks = _queuePerFileSubtasks(transaction, subtask, todo[TAX], TAX, taxFiles)
        deedSubtasks = _queuePerFileSubtasks(transaction, subtask, todo[DEED], DEED, deedFiles)
        finalizePrep = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_finalizeDataPrep", {sources: _.keys(todo)}, true)
        activate = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_activateNewData", {deletes: deletes}, true)
        dates = jobQueue.queueSubsequentSubtask(transaction, subtask, 'corelogic_saveProcessDates', dates: dates, true)
        Promise.join ftpEnd, taxSubtasks, deedSubtasks, finalizePrep, activate, dates, () ->  # empty handler

_queuePerFileSubtasks = (transaction, subtask, dir, type, files) -> Promise.try () ->
  if !files?.length
    return
  loadDataList = []
  countDataList = []
  for file in files when file.name.endsWith('.zip')
    rawTableSuffix = "#{file.name.slice(0, -4)}"
    loadDataList.push
      path: "/#{dir}/#{file.name}"
      rawTableSuffix: rawTableSuffix
      dataType: type
    countDataList.push
      rawTableSuffix: rawTableSuffix
      dataType: type
      deletes: if type == TAX then dataLoadHelpers.DELETE.UNTOUCHED else dataLoadHelpers.DELETE.INDICATED  # tax data is full-dump, deed data is incremental
      subset:
        fips_code: file.name.slice(3, -4)
  loadRawDataPromise = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_loadRawData", loadDataList, true)
  recordChangeCountsPromise = jobQueue.queueSubsequentSubtask(transaction, subtask, "corelogic_recordChangeCounts", countDataList, true)
  Promise.join loadRawDataPromise, recordChangeCountsPromise, () ->  # empty handler

loadRawData = (subtask) ->
  countyHelpers.loadRawData subtask,
    dataSourceId: 'corelogic'
    columnsHandler: (columnsLine) -> columnsLine.replace(/[^a-zA-Z0-9\t]+/g, ' ').toInitCaps().split('\t')
    delimiter: '\t'
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask null, subtask, numRows, NUM_ROWS_TO_PAGINATE, "corelogic_normalizeData",
      rawTableSuffix: subtask.data.rawTableSuffix
      dataType: subtask.data.dataType

saveProcessedDates = (subtask) ->
  keystore.setValuesMap(subtask.data.dates, namespace: CORELOGIC_PROCESS_DATES)

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: 'corelogic'
    dataSourceType: 'county'
    buildRecord: countyHelpers.buildRecord

finalizeDataPrep = (subtask) ->
  Promise.map subtask.data.sources, (source) ->
    tables.property[source]()
    .select('rm_property_id')
    .where(batch_id: subtask.batch_id)
    .then (ids) ->
      _.pluck(ids, 'rm_property_id')
  .then (lists) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, _.union(lists), NUM_ROWS_TO_PAGINATE, "corelogic_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, countyHelpers.finalizeData.bind(null, subtask)


module.exports = new TaskImplementation
  checkFtpDrop: checkFtpDrop
  loadRawData: loadRawData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData
