Buffer = require('buffer').Buffer
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
keystore = require '../services/service.keystore'
TaskImplementation = require './util.taskImplementation'
moment = require 'moment'
internals = require './task.blackknight.internals'
validation = require '../utils/util.validation'


copyFtpDrop = (subtask) ->
  ftp = new PromiseSftp()
  now = Date.now()

  # path containers that are populated below
  defaults = {}
  defaults[internals.REFRESH] = '19700101'
  defaults[internals.UPDATE] = '19700101'
  defaults[internals.NO_NEW_DATA_FOUND] = '19700101'

  # dates for which we've processed blackknight files are tracked in keystore
  keystore.getValuesMap(internals.BLACKKNIGHT_COPY_DATES, defaultValues: defaults)
  .then (copyDates) ->

    logger.debug () -> "dates for file search: #{JSON.stringify(copyDates)}"

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
      refreshPromise = internals.findNewFolders(ftp, internals.REFRESH, copyDates)
      .then (newFolders) ->
        logger.debug () -> "Found #{Object.keys(newFolders).length} newFolders for REFRESH list"
        if _.isEmpty(newFolders)
          return []

        # sort to help us get oldest date...
        drops = Object.keys(newFolders).sort()
        refresh = newFolders[drops[0]]
        # track the dates we got here and send out the tax/deed/mortgage paths
        copyDates[internals.REFRESH] = refresh.date
        return [refresh.tax.path, refresh.deed.path, refresh.mortgage.path]

      # UPDATE paths/files for tax, deed, and mortgage
      updatePromise = internals.findNewFolders(ftp, internals.UPDATE, copyDates)
      .then (newFolders) ->
        logger.debug () -> "Found #{Object.keys(newFolders).length} newFolders for UPDATE list"
        if _.isEmpty(newFolders)
          return []

        # sort to help us get oldest date...
        drops = Object.keys(newFolders).sort()
        update = newFolders[drops[0]]
        # track the dates we got here and send out the tax/deed/mortgage paths
        copyDates[internals.UPDATE] = update.date
        return [update.tax.path, update.deed.path, update.mortgage.path]

      # concat the paths from both sources
      Promise.join(refreshPromise, updatePromise)
      .then ([refreshPaths, updatePaths]) ->
        return refreshPaths.concat updatePaths

    .catch (err) ->
      throw new SoftFail("Error reading blackknight FTP: #{err}")

    # expect a list of 6 paths here, for one date of processing
    .then (paths) ->
      logger.debug () -> "Processing blackknight paths: #{JSON.stringify(paths)}"

      # traverse each path...
      Promise.map paths, (path) ->
        ftp.list(path)
        .then (files) ->
          _.forEach files, (el) -> el.fullpath = "#{path}/#{el.name}"
          files

      # queue up individual subtasks for each file transfer
      .then (fileList) ->

        # flatten list of lists from the Promise.map...
        fileList = _.flatten(fileList)

        # remove 0 size files
        fileList = _.filter fileList, (el) -> el.size > 0

        ftp.logout()
        .then () ->
          dbs.transaction 'main', (transaction) ->
            fileProcessing = jobQueue.queueSubsequentSubtask({transaction, subtask, laterSubtaskName: 'copyFile', manualData: fileList, replace: true})
            dates = keystore.setValuesMap(copyDates, namespace: internals.BLACKKNIGHT_COPY_DATES)
            Promise.join fileProcessing, dates, () -> # empty handler


copyFile = (subtask) ->
  ftp = new PromiseSftp()
  file = subtask.data
  logger.debug () -> "copying blackknight file #{file.fullpath}, size=#{file.size}, type=#{file.type}"

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

    # setup input ftp stream
    ftp.get(file.fullpath)
    .then (ftpStream) -> new Promise (resolve, reject) ->

      # debug helpers
      ftpStreamChunks = 0
      s3UploadParts = 0

      # stream events
      ftpStream.on('error', reject)
      ftpStream.on 'data', (buffer) ->
        ftpStreamChunks++

      # procure writable aws stream
      config =
        extAcctName: awsService.buckets.BlackknightData
        Key: file.fullpath.substring(1) # omit leading slash
        ContentType: 'text/plain'
      awsService.upload(config)
      .then (upload) ->
        logger.debug () -> "Acquired upload stream to s3, transfering file..."

        upload.concurrentParts(10)
        upload.on('error', reject)
        upload.on('uploaded', resolve)

        upload.on 'part', (details) ->
          s3UploadParts++
          logger.debug () -> "s3Upload (writing): Large file (#{file.size} Bytes), `part` event ##{s3UploadParts}:\n#{JSON.stringify(details,null,2)}\nincludes #{ftpStreamChunks} ftp stream chunks."


        ftpStream.pipe(upload)
    .catch (err) -> # catches ftp errors
      throw new SoftFail("SFTP error while copying #{file.fullpath}: #{err}")

  .catch (err) ->
    throw new SoftFail("Error transfering files from Blackknight to S3: #{err}")
  .then () ->
    ftp.logout()


checkFtpDrop = (subtask) ->
  defaults = {}
  defaults[internals.REFRESH] = '19700101'
  defaults[internals.UPDATE] = '19700101'
  defaults[internals.NO_NEW_DATA_FOUND] = '19700101'
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
    else
      laterSubtaskName = "normalizeData"
      mergeData.startTime = subtask.data.startTime
      numRowsToPage = subtask.data?.numRowsToPageNormalize || internals.NUM_ROWS_TO_PAGINATE

    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRows, maxPage: numRowsToPage, laterSubtaskName, mergeData})


saveProcessDates = (subtask) ->
  internals.popProcessingDates(subtask.data.dates)


deleteData = (subtask) ->
  normalDataTable = tables.normalized[subtask.data.dataType]
  dataLoadHelpers.getRawRows(subtask)
  .then (rows) ->
    Promise.each rows, (row) ->
      if row['FIPS Code'] != '12021'
        Promise.resolve()

      else if subtask.data.action == internals.REFRESH
        # delete the entire FIPS, we're loading a full refresh
        normalDataTable(subid: row['FIPS Code'])
        .where
          data_source_id: 'blackknight'
          fips_code: row['FIPS Code']
        .whereNull('deleted')
        .update(deleted: subtask.batch_id)
        .catch (err) ->
          throw new SoftFail("Error while deleting for full refresh for fips=#{row['FIPS Code']}, batch_id=#{subtask.batch_id}\n#{err}")

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


ready = () ->
  # don't automatically run if digimaps is running
  tables.jobQueue.taskHistory()
  .where
    current: true
    name: 'digimaps'
  .whereNull('finished')
  .then (results) ->
    if results?.length
      # found an instance of digimaps, GTFO
      return false

    # if we didn't bail above, do some other special logic for efficiency
    defaults = {}
    defaults[internals.REFRESH] = '19700101'
    defaults[internals.UPDATE] = '19700101'
    defaults[internals.NO_NEW_DATA_FOUND] = '19700101'
    keystore.getValuesMap(internals.BLACKKNIGHT_PROCESS_DATES, defaultValues: defaults)
    .then (processDates) ->
      # run task if there are dates to process
      if processDates[internals.REFRESH].length > 0 || processDates[internals.UPDATE].length > 0
        return true

      keystore.getValuesMap(internals.BLACKKNIGHT_COPY_DATES, defaultValues: defaults)
      .then (copyDates) ->
        # UTC for us will effectively be 8:00pm our time (barring DST, the approximate time here + or - an hour is fine)
        today = moment.utc().format('YYYYMMDD')
        yesterday = moment.utc().subtract(1, 'day').format('YYYYMMDD')
        dayOfWeek = moment.utc().isoWeekday()

        if copyDates[internals.NO_NEW_DATA_FOUND] != today
          # needs to run using regular logic
          return undefined
        else if dayOfWeek == 7 || dayOfWeek == 1
          # Sunday or Monday, because drops don't happen at the end of Saturday and Sunday
          keystore.setValue(internals.NO_NEW_DATA_FOUND, today, namespace: internals.BLACKKNIGHT_COPY_DATES)
          .then () ->
            return false

        # check for empty processDates list?
        else if copyDates[internals.REFRESH] == yesterday && copyDates[internals.UPDATE] == yesterday
          # we've already processed yesterday's data
          keystore.setValue(internals.NO_NEW_DATA_FOUND, today, namespace: internals.BLACKKNIGHT_COPY_DATES)
          .then () ->
            return false

        else
          # no overrides, needs to run using regular logic
          return undefined


recordChangeCounts = (subtask) ->
  dataLoadHelpers.recordChangeCounts(subtask, {deletesTable: 'combined'})


subtasks = {
  copyFtpDrop
  copyFile
  checkFtpDrop
  loadRawData
  deleteData
  normalizeData
  recordChangeCounts
  finalizeDataPrep
  finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  saveProcessDates
}
module.exports = new TaskImplementation('blackknight', subtasks, ready)
