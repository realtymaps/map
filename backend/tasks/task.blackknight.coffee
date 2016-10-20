fs = require 'fs'
rimraf = require 'rimraf'
Promise = require "bluebird"
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:blackknight')
countyHelpers = require './util.countyHelpers'
externalAccounts = require '../services/service.externalAccounts'
PromiseSftp = require 'promise-sftp'
awsService = require '../services/service.aws'
_ = require 'lodash'
dbs = require '../config/dbs'
keystore = require '../services/service.keystore'
TaskImplementation = require './util.taskImplementation'
moment = require 'moment'
internals = require './task.blackknight.internals'
validation = require '../utils/util.validation'


copyFtpDrop = (subtask) ->
  ftp = new PromiseSftp()

  # date for which blackknight files we've processed is tracked in keystore
  keystore.getValue(internals.LAST_COMPLETED_DATE, namespace: internals.BLACKKNIGHT_COPY_INFO, defaultValue: '19700101')
  .then (copyDate) ->

    logger.debug () -> "date for file search: #{JSON.stringify(copyDate)}"

    # establish ftp connection to blackknight
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

      # REFRESH paths/files for tax, deed, and mortgage
      refreshPromise = internals.findNextFolderSet(ftp, internals.REFRESH, copyDate)

      # UPDATE paths/files for tax, deed, and mortgage
      updatePromise = internals.findNextFolderSet(ftp, internals.UPDATE, copyDate)

      # concat the paths from both sources
      Promise.join refreshPromise, updatePromise, (refresh, update) ->
        if refresh.date == update.date
          if refresh.date == '99999999'
            return {paths: []}
          return {
            date: refresh.date
            paths: [refresh.tax, refresh.deed, refresh.mortgage, update.tax, update.deed, update.mortgage]
          }
        if refresh.date < update.date
          return {
            date: refresh.date
            paths: [refresh.tax, refresh.deed, refresh.mortgage]
          }
        else  # update.date < refresh.date
          return {
            date: update.date
            paths: [update.tax, update.deed, update.mortgage]
          }

    .catch (err) ->
      throw new SoftFail("Error reading blackknight FTP: #{err}")

  # expect 6 paths in the folder set
  .then (folderSet) ->
    logger.debug () -> "Processing blackknight paths: #{JSON.stringify(folderSet)}"

    # traverse each path...
    filteredFiles = []
    Promise.each folderSet.paths, (path) ->
      ftp.list(path)
      .then (files) ->
        for file in files
          if file.size > 0
            filteredFiles.push
              name: file.name
              path: path
              size: file.size
    # queue up individual subtasks for each file transfer
    .then () ->

      logger.debug () -> "Queuing copy subtasks for files: #{JSON.stringify(filteredFiles)}"
      ftp.logout()
      .then () ->
        dbs.transaction (transaction) -> Promise.try () ->
          if filteredFiles.length > 0
            # queue up file copies
            jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: 'copyFile', manualData: filteredFiles, replace: true, concurrency: 10})
            # save / push new dates
            jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: 'saveCopyDate', manualData: {date: folderSet.date}, replace: true})
          else
            # record that there isn't anything to see today
            keystore.setValue(internals.NO_NEW_DATA_FOUND, moment.utc().format('YYYYMMDD'), namespace: internals.BLACKKNIGHT_COPY_INFO)


copyFile = (subtask) ->
  ftp = new PromiseSftp()
  file = subtask.data
  fullpath = "#{file.path}/#{file.name}"
  logger.debug () -> "copying blackknight file #{fullpath}, size=#{file.size}"

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
    localfile = "/tmp/#{(new Date()).getTime()}_#{file.name}"

    logger.debug () -> "fastGet from (source): #{fullpath}"
    logger.debug () -> "fastGet to   (target): #{localfile}"

    # ensure local file doesn't exist
    rimraf.async(localfile)
    .then () ->

      # ftp down file
      # Note: as of PromiseSftp version 0.9.9, using ftp.get() was buggy here; defered to fastGet which works
      ftp.fastGet(fullpath, localfile)
    .then () -> new Promise (resolve, reject) ->

      config =
        extAcctName: awsService.buckets.BlackknightData
        Key: fullpath.substring(1) # omit leading slash
        ContentType: 'text/plain'

      # s3 up file
      awsService.upload(config)
      .then (upload) ->
        logger.debug () -> "Acquired upload stream to s3, transfering file..."

        upload.on('error', reject)
        upload.on('uploaded', resolve)

        fs.createReadStream(localfile).pipe(upload)

    .catch (err) -> # catches ftp errors
      throw new SoftFail("SFTP error while copying #{fullpath}: #{err}")

  .catch (err) ->
    throw new SoftFail("Error transfering files from Blackknight to S3: #{err}")
  .then () ->
    logger.debug () -> "File transfer complete."
    ftp.logout()

saveCopyDate = (subtask) ->
  keystore.setValue(internals.LAST_COMPLETED_DATE, subtask.data.date, namespace: internals.BLACKKNIGHT_COPY_INFO)
  .then () ->
    logger.debug () -> "saved blackknight copy date: #{JSON.stringify(subtask.data.date)}"
    internals.pushProcessingDate(subtask.data.date)


checkProcessQueue = (subtask) ->
  subtaskStartTime = Date.now()

  # send classified file lists through downloading and processing
  internals.getProcessInfo(subtask, subtaskStartTime)
  .then (processInfo) ->
    internals.useProcessInfo(subtask, processInfo)


loadRawData = (subtask) ->
  internals.getColumns(subtask.data.fileType, subtask.data.action, subtask.data.dataType)
  .then (columns) ->
    # download and insert data with `countyHelpers`
    countyHelpers.loadRawData subtask,
      dataSourceId: 'blackknight'
      columnsHandler: columns
      delimiter: '\t'
      s3account: awsService.buckets.BlackknightData

  .then (numRows) ->
    mergeData =
      rawTableSuffix: subtask.data.rawTableSuffix
      dataType: subtask.data.dataType
      action: subtask.data.action
      normalSubid: subtask.data.normalSubid
    if subtask.data.fileType == internals.DELETE
      laterSubtaskName = "deleteData"
      numRowsToPage = subtask.data?.numRowsToPageDelete || internals.NUM_ROWS_TO_PAGINATE
      mergeData.fips_code = subtask.data.fips_code
      mergeData.rawDeleteBatchId = subtask.batch_id
      fauxSubtask = _.extend({}, subtask, data: mergeData)
      # get the number of rows pertaining to the current fips code
      totalNumRowsPromise = tables.temp(subid: dataLoadHelpers.buildUniqueSubtaskName(fauxSubtask))
      .where('FIPS Code': mergeData.fips_code)
      .count('*')
      .then (count) ->
        count?[0]?.count || 0
    else
      laterSubtaskName = "normalizeData"
      mergeData.startTime = subtask.data.startTime
      numRowsToPage = subtask.data?.numRowsToPageNormalize || internals.NUM_ROWS_TO_PAGINATE
      totalNumRowsPromise = Promise.resolve(numRows)

    totalNumRowsPromise
    .then (totalNumRows) ->
      jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: totalNumRows, maxPage: numRowsToPage, laterSubtaskName, mergeData})


cleanup = (subtask) ->
  keystore.setValue('blackknightExclusiveAccess', false, namespace: 'locks')
  .then () ->
    internals.updateProcessInfo(subtask.data)


deleteData = (subtask) ->
  normalDataTable = tables.normalized[subtask.data.dataType]
  rawSubid = dataLoadHelpers.buildUniqueSubtaskName(subtask, subtask.data.rawDeleteBatchId)
  dataLoadHelpers.getRawRows(subtask, rawSubid, 'FIPS Code': subtask.data.fips_code)
  .then (rows) ->
    Promise.each rows, (row) ->
      if subtask.data.action == internals.REFRESH
        # delete the entire FIPS, we're loading a full refresh
        normalDataTable(subid: row['FIPS Code'])
        .where
          data_source_id: 'blackknight'
          fips_code: row['FIPS Code']
        .whereNull('deleted')
        .update(deleted: subtask.batch_id)
        .catch (err) ->
          throw new SoftFail("Error while deleting for full refresh for fips=#{row['FIPS Code']}, batch_id=#{subtask.batch_id}\n#{err}")
        .then () ->
          if subtask.data.dataType == internals.TAX
            keystore.setValue(internals.DELETED_FIPS, true, {namespace: internals.BLACKKNIGHT_PROCESS_INFO})


      else if subtask.data.dataType == internals.TAX
        # get validation for parcel_id
        dataLoadHelpers.getValidationInfo('county', 'blackknight', subtask.data.dataType, 'base', 'parcel_id')
        .then (validationInfo) ->
          Promise.props(_.mapValues(validationInfo.validationMap, validation.validateAndTransform.bind(null, row)))
        .then (normalizedData) ->
          parcel_id = normalizedData.parcel_id || (_.find(normalizedData.base, (obj) -> obj.name == 'parcel_id')).value
          if !parcel_id?
            logger.warn("Unable to locate a parcel_id in validated `normalizedData` while processing deletes.")

          normalDataTable(subid: row['FIPS Code'])
          .where
            data_source_id: 'blackknight'
            fips_code: row['FIPS Code']
            parcel_id: parcel_id
          .update(deleted: subtask.batch_id)
          .catch (err) ->
            logger.debug () -> "normalizedData: #{JSON.stringify(normalizedData)}"
            throw new SoftFail(err, "Error while updating delete for fips=#{row['FIPS Code']} batch_id=#{subtask.batch_id}, parcel_id=#{parcel_id}")

      else
        # get validation for data_source_uuid
        dataLoadHelpers.getValidationInfo('county', 'blackknight', subtask.data.dataType, 'base', 'data_source_uuid')
        .then (validationInfo) ->
          Promise.props(_.mapValues(validationInfo.validationMap, validation.validateAndTransform.bind(null, row)))
        .then (normalizedData) ->
          data_source_uuid = normalizedData.data_source_uuid || (_.find(normalizedData.base, (obj) -> obj.name == 'data_source_uuid')).value
          if !data_source_uuid?
            logger.warn("Unable to locate a data_source_uuid in validated `normalizedData` while processing deletes.")

          normalDataTable(subid: row['FIPS Code'])
          .where
            data_source_id: 'blackknight'
            fips_code: row['FIPS Code']
            data_source_uuid: data_source_uuid
          .update(deleted: subtask.batch_id)
          .catch (err) ->
            logger.debug () -> "normalizedData: #{JSON.stringify(normalizedData)}"
            throw new SoftFail(err, "Error while updating delete for fips=#{row['FIPS Code']} batch_id=#{subtask.batch_id}, data_source_uuid=#{normalizedData.data_source_uuid}", err)


normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: 'blackknight'
    dataSourceType: 'county'
    buildRecord: countyHelpers.buildRecord


# not used as a task since it is in normalizeData
# however this makes finalizeData accessible via the subtask script
finalizeDataPrep = (subtask) ->
  {normalSubid} = subtask.data
  if !normalSubid?
    throw new SoftFail "normalSubid required"

  tables.normalized.tax(subid: normalSubid)
  .select('rm_property_id')
  .then (results) ->
    jobQueue.queueSubsequentPaginatedSubtask {
      subtask,
      totalOrList: _.pluck(results, 'rm_property_id')
      maxPage: 100
      laterSubtaskName: "finalizeData"
      mergeData:
        normalSubid: normalSubid
    }

finalizeData = (subtask) ->
  Promise.each subtask.data.values, (id) ->
    countyHelpers.finalizeData({subtask, id})


###
This step is an in-between to protect a following step from being run.
In this case we are hoping to protect activateData from running while MLSs are doing the same thing.

This is not due to a hard problem with having 2 tasks each running activateData at the same time, but there is a soft
problem with db performance.
###
waitForExclusiveAccess = (subtask, prefix) ->
  keystore.setValue('blackknightExclusiveAccess', true, namespace: 'locks')
  .then () ->
    tables.jobQueue.taskHistory()
    .select('name')
    .where(current: true)
    .whereRaw("blocked_by_locks \\? 'blackknightExclusiveAccess'")
    .whereNull('finished')
    .then (results=[]) ->
      if results.length > 0
        # quietly retry the subtask.  This is safer than trying to poll internally, because a
        # polling flow can't handle zombies, but a retrying flow can
        msg = "blackknight_waitForExclusiveAccess: exclusive data_combined access unavailable due to: #{_.pluck(results, 'name').join(', ')}"
        jobQueue.retrySubtask({subtask, prefix, error: msg, quiet: true})
      else
        logger.info("Exclusive data_combined access obtained")
        # go ahead and resolve, so the subtask will finish and the task will continue
        return null


ready = () ->
  # do some special logic for efficiency
  processDefaults = {}
  processDefaults[internals.DATES_QUEUED] = []
  processDefaults[internals.FIPS_QUEUED] = []
  copyDefaults = {}
  copyDefaults[internals.REFRESH] = '19700101'
  copyDefaults[internals.UPDATE] = '19700101'
  copyDefaults[internals.NO_NEW_DATA_FOUND] = '19700101'
  keystore.getValuesMap(internals.BLACKKNIGHT_PROCESS_INFO, defaultValues: processDefaults)
  .then (processInfo) ->
    # definitely run task if there are new dates and/or FIPS to process
    if processInfo[internals.DATES_QUEUED].length > 0 || processInfo[internals.FIPS_QUEUED].length > 0
      return true

    keystore.getValuesMap(internals.BLACKKNIGHT_COPY_INFO, defaultValues: copyDefaults)
    .then (copyDates) ->
      # UTC for us will effectively be 8:00pm our time (barring DST, the approximate time here + or - an hour is fine)
      now = moment.utc()
      today = now.format('YYYYMMDD')
      yesterday = now.subtract(1, 'day').format('YYYYMMDD')
      dayOfWeek = now.isoWeekday()

      if copyDates[internals.NO_NEW_DATA_FOUND] == today
        # we've already indicated there's no new data to find today
        return false
      else if dayOfWeek == 7 || dayOfWeek == 1
        # Sunday or Monday, because drops don't happen at the end of Saturday and Sunday
        keystore.setValue(internals.NO_NEW_DATA_FOUND, today, namespace: internals.BLACKKNIGHT_COPY_INFO)
        .then () ->
          return false
      else if copyDates[internals.REFRESH] == yesterday && copyDates[internals.UPDATE] == yesterday
        # we've already processed yesterday's data
        keystore.setValue(internals.NO_NEW_DATA_FOUND, today, namespace: internals.BLACKKNIGHT_COPY_INFO)
        .then () ->
          return false
      else
        # no overrides, ready to run
        return true


recordChangeCounts = (subtask) ->
  if subtask.data.dataType != internals.TAX
    indicatePromise = Promise.resolve(false)
  else if subtask.data.action != internals.REFRESH
    indicatePromise = Promise.resolve(true)
  else
    indicatePromise = keystore.getValue(internals.DELETED_FIPS, namespace: internals.BLACKKNIGHT_PROCESS_INFO)
    .then (deletedFips) ->
      return !deletedFips
  indicatePromise
  .then (indicateDeletes) ->
    dataLoadHelpers.recordChangeCounts(subtask, {deletesTable: 'combined', indicateDeletes})


activateNewData = (subtask) ->
  keystore.getValue(internals.DELETED_FIPS, namespace: internals.BLACKKNIGHT_PROCESS_INFO)
  .then (deletedFips) ->
    deletes = if deletedFips then dataLoadHelpers.DELETE.UNTOUCHED else dataLoadHelpers.DELETE.INDICATED
    dataLoadHelpers.activateNewData(subtask, {deletes})


subtasks = {
  copyFtpDrop
  copyFile
  saveCopyDate
  checkProcessQueue
  loadRawData
  deleteData
  normalizeData
  recordChangeCounts
  finalizeDataPrep
  finalizeData
  waitForExclusiveAccess
  activateNewData
  cleanup
}
module.exports = new TaskImplementation('blackknight', subtasks, ready)
