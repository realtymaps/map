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
keystore = require '../services/service.keystore'


NUM_ROWS_TO_PAGINATE = 500
CORELOGIC_PROCESS_DATES = 'corelogic process dates'
TAX = 'Tax'
DEED = 'Deeds'


checkFtpDrop = (subtask) ->
  ftp = new PromiseFtp()
  connectPromise = ftp.connect
    host: subtask.task_data.host
    user: subtask.task_data.user
    password: encryptor.decrypt(subtask.task_data.password)
  .then (msg) ->
    console.log("\n######## FTP message:\n#{msg}")
    ftp.list('/')
  defaultValues = {}
  defaultValues[TAX] = '19700101'
  defaultValues[DEED] = '19700101'
  processDatesPromise = keystore.propertyDb.getValuesMap CORELOGIC_PROCESS_DATES, defaultValues: defaultValues
  Promise.join connectPromise, processDatesPromise, (rootListing, processDates) ->
    console.log '######## corelogic process dates:\n' + JSON.stringify(processDates,null,2)
    console.log '######## root listing:\n' + _.pluck(rootListing, 'name').join('\n')
    todo = {}
    for dir in _.sortBy(rootListing, 'name') when dir.type == 'd' then do (dir) ->
      date = dir.name.slice(0, 8)
      type = dir.name.slice(8)
      console.log "======== checking out dir from #{date} for #{type}:"
      if !processDates[type]?
        logger.warn("Unexpected directory found in corelogic FTP drop: #{dir.name}")
        return
      if processDates[type] >= date
        logger.debug("Skipping...")
        return
      if type == TAX
        # tax drops are full dumps, so ignore all but the last
        todo[TAX] = date
      else  # type == DEED
        # deed files are incremental updates, so we need the earliest unprocessed drop
        if todo[DEED]?
          todo[DEED] = date
      controlPromise = controlPromise
      .then () ->
        ftp.list("/#{dir.name}")
      .then (dirListing) ->
          # tax files are full dumps, so ignore all but the last
          for file in dirListing when file.type == '-' && file.name.endsWith('.zip') then do (file) ->
            fips = file.name.slice(3, -4)
            taxTodo[fips] = date
          deedTodo[fips] = (deedTodo[fips] ? []).push(date)
    controlPromise
  .then () ->
    ftp.end()
  .then () ->
    console.log "######## disconnected"

loadRawData = (subtask) ->
  coreLogicHelpers.loadUpdates subtask,
    rawTableSuffix: 'main'
    dataSourceId: subtask.task_name
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, numRows, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_normalizeData")

normalizeData = (subtask) ->
  coreLogicHelpers.normalizeData subtask,
    rawTableSuffix: 'main'
    dataSourceId: subtask.task_name

finalizeDataPrep = (subtask) ->
  tables.propertyData.mls()
  .distinct('rm_property_id')
  .select()
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, _.pluck(ids, 'rm_property_id'), NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, coreLogicHelpers.finalizeData.bind(null, subtask)
  

subtasks =
  checkFtpDrop: checkFtpDrop
  loadRawData: loadRawData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts.bind(null, 'main', tables.propertyData.mls)
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name.replace(/[^_]+_/g,'')](subtask)
