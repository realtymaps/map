Promise = require 'bluebird'
_ = require 'lodash'
moment = require 'moment'
path = require 'path'
# cartoDbSvc = require '../services/service.cartodb'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dataLoadHelpers = require './util.dataLoadHelpers'
externalAccounts = require '../services/service.externalAccounts'
parcelsFetch = require '../services/service.parcels.fetcher.digimaps'
parcelHelpers = require './util.parcelHelpers'
TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger.coffee').spawn('task:digimaps')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
{NoShapeFilesError, UnzipError} = require('shp2jsonx').errors
util = require 'util'


NUM_ROWS_TO_PAGINATE = 250
HALF_YEAR_MILLISEC = moment.duration(year:1).asMilliseconds() / 2
DELAY_MILLISECONDS = 250

_filterImports = (subtask, imports) ->
  dataLoadHelpers.getUpdateThreshold({subtask, fullRefreshMillis: HALF_YEAR_MILLISEC})
  .then (refreshThreshold) ->
    folderObjs = imports.map (l) ->
      name: l
      moment: moment(String.numeric(l), 'YYYYMMDD').utc()

    folderObjs = _.filter folderObjs, (o) ->
      o.moment.isAfter(moment(refreshThreshold).utc())


    if subtask.data.fipsCodeLimit?
      logger.debug "@@@@@@@@@@@@@ fipsCodeLimit: #{subtask.data.fipsCodeLimit}"
      folderObjs = _.take folderObjs, subtask.data.fipsCodeLimit

    # folderObjs = _.filter folderObjs, (f) -> #NOTE: for testing ONLY
      # bad = f.match /17049/
      # good = f.match /06009/

    fileNames = folderObjs.map (f) -> f.name
    fipsCodes = fileNames.map (name) -> String.numeric path.basename name

    logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@ fipsCodes Available from digimaps @@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    logger.debug fipsCodes

    if subtask.data.fipsCodes? && _.isArray subtask.data.fipsCodes
      fileNames = _.filter fileNames, (name) ->
        _.any subtask.data.fipsCodes, (code) ->
          name.match new RegExp(code)

      fipsCodes = fileNames.map (name) -> String.numeric path.basename name

    logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@ filtered fipsCodes  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    logger.debug fipsCodes

    {
      filteredImports: fileNames
      refreshThreshold
      fipsCodes
    }

loadRawDataPrep = (subtask) -> Promise.try () ->
  logger.debug util.inspect(subtask, depth: null)

  now = Date.now()

  externalAccounts.getAccountInfo(subtask.task_name)
  .then (creds) ->
    parcelsFetch.defineImports({creds})
  .then (imports) ->
    _filterImports(subtask, imports)
  .then ({filteredImports, refreshThreshold}) ->

    filteredImports = filteredImports.map (f) ->
      fileName: f
      refreshThreshold: refreshThreshold
      startTime: now

    Promise.all [
      jobQueue.queueSubsequentSubtask {
        subtask
        manualData: filteredImports
        laterSubtaskName: 'loadRawData'
      }

      jobQueue.queueSubsequentSubtask {
        subtask, laterSubtaskName: "activateNewData"
        manualData: {deletes: dataLoadHelpers.DELETE.INDICATED}
        replace: true
        startTime: subtask.data.startTime
      }
    ]

loadRawData = (subtask) -> Promise.try () ->
  logger.debug util.inspect(subtask, depth: null)

  {fileName} = subtask.data
  fipsCode = String.numeric path.basename fileName
  numRowsToPageNormalize = subtask.data?.numRowsToPageNormalize || NUM_ROWS_TO_PAGINATE

  subtask.data.rawTableSuffix = fipsCode

  rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))

  dataLoadHistory =
    data_source_id: "#{subtask.task_name}_#{fipsCode}"
    data_source_type: 'parcel'
    data_type: 'parcel'
    batch_id: subtask.batch_id
    raw_table_name: rawTableName

  externalAccounts.getAccountInfo(subtask.task_name)
  .then (creds) ->
    parcelsFetch.getParcelJsonStream(fileName, {creds})
    .then (jsonStream) ->

      dataLoadHelpers.manageRawJSONStream({
        tableName: rawTableName
        dataLoadHistory
        jsonStream
        column: parcelHelpers.column
      })
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
      .catch (error) ->
        throw new SoftFail error.message
    .catch NoShapeFilesError, (error) ->
      parcelHelpers.handleOveralNormalizeError {error, dataLoadHistory, numRawRows: 0, fileName}
    .catch UnzipError, (error) ->
      parcelHelpers.handleOveralNormalizeError {error, dataLoadHistory, numRawRows: 0, fileName}
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to load parcels data for update')
    .catch (error) ->
      throw new SoftFail(analyzeValue.getSimpleMessage(error))
    .then (numRawRows) ->
      if numRawRows == 0
        return 0
      # now that we know we have data, queue up the rest of the subtasks
      logger.debug("num rows to normalize: #{numRows}")
      normalizeDataPromise = jobQueue.queueSubsequentPaginatedSubtask {
        subtask
        totalOrList: numRows
        maxPage: numRowsToPageNormalize
        laterSubtaskName: "normalizeData"
        mergeData: {
          fipsCode
          dataType: 'parcel'
          rawTableSuffix: fipsCode
          startTime: subtask.data.startTime
        }
      }
      recordChangeCountsPromise = jobQueue.queueSubsequentSubtask {
        subtask
        laterSubtaskName: "recordChangeCounts"
        #rawDataType fixes lookup of rawtable for change counts
        manualData: parcelHelpers.getRecordChangeCountsData(fipsCode)
        replace: true
      }
      Promise.join normalizeDataPromise, recordChangeCountsPromise, () ->  # no-op

normalizeData = (subtask) ->
  logger.debug util.inspect(subtask, depth: null)

  {fipsCode,  delay} = subtask.data

  dataLoadHelpers.getRawRows subtask
  .then (rows) ->
    if !rows?.length
      logger.debug () -> "no raw rows found for rm_raw_id #{subtask.data.offset+1} to #{subtask.data.offset+subtask.data.count}"
      return
    logger.debug () -> "got #{rows.length} raw rows"

    parcelHelpers.saveToNormalDb {
      subtask
      rows
      fipsCode
      delay: delay ? DELAY_MILLISECONDS
    }

# not used as a task since it is in normalizeData
# however this makes finalizeData accessible via the subtask script
finalizeDataPrep = (subtask) ->
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE
  fipsCode = subtask.data?.fipsCode

  if !fipsCode?
    throw new HardFail('fipsCode is required for finalizedDataPrep')

  logger.debug util.inspect(subtask, depth: null)

  tables.property.normParcel()
  .select('rm_property_id')
  .where
    batch_id: subtask.batch_id
    fips_code: fipsCode
  .then (ids) ->
    ids  = _.pluck(ids, 'rm_property_id')
    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: ids
      maxPage: numRowsToPageFinalize
      laterSubtaskName: "finalizeData"
      mergeData:
        normalSubid: fipsCode #required for countyHelpers.finalizeData
    }

###
This step is an in-between to protect a following step from being run.
In this case we are hoping to protect finalizeData (not prep) and activateData.

This is due to the fact that mls or county could be finalizing and activating data at the same time.
Since parcels can modify both mls and county rows in data_combined weird results could happen.

The opposite is true of county and mls since they only modify their perspective and exclusive rows.
###
waitForExclusiveAccess = (subtask) ->
  tables.config.mls()
  .select('id')
  .then (excludeIds) ->
    excludeIds.concat(subtask.data.additionalExclusions)
    tables.jobQueue.taskHistory()
    .where(current: true)
    .whereIn('name', excludeIds)
    .whereNull('finished')
    .then (results=[]) ->
      if results.length > 0
        logger.info("Waiting for exclusive data_combined access; #{results.length} tasks remaining: #{results.join(', ')}")
        # Create a promise that doesn't finish on its own -- it just waits to get timed out and retried.  This is safer
        # than trying to poll internally, because a polling flow can't handle zombies, but a retrying flow can
        return new Promise (resolve, reject) ->  # noop
      else
        logger.info("Exclusive data_combined access obtained")
        # go ahead and resolve, so the subtask will finish and the task will continue
        return null


finalizeData = (subtask) ->
  # logger.debug () -> util.inspect(subtask, depth: null)
  logger.debug () -> 'beginning finalizeData'

  {delay, normalSubid} = subtask.data

  if !normalSubid?
    throw new HardFail "normalSubid must be defined"

  Promise.each subtask.data.values, (id) ->
    parcelHelpers.finalizeData(subtask, id, delay ? DELAY_MILLISECONDS)
  # .then ->
  #   jobQueue.queueSubsequentSubtask {
  #     subtask,
  #     laterSubtaskName: 'syncCartoDb'
  #     manualData: subtask.data
  #     replace: true
  #   }

recordChangeCounts = (subtask) ->
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE

  dataLoadHelpers.recordChangeCounts(subtask, indicateDeletes: true, deletesTable: 'parcel')
  .then (deletedIds) ->
    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: deletedIds
      maxPage: numRowsToPageFinalize
      laterSubtaskName: "finalizeData"
      mergeData:
        normalSubid: subtask.data.subset.fips_code  # required for countyHelpers.finalizeData
        deletedParcel: true
    }

# syncCartoDb: (subtask) -> Promise.try ->
#   fipsCode = String.numeric path.basename subtask.task_data
#   parcel.upload(fipsCode)
#   .then ->
#     parcel.synchronize(fipsCode)
#     #WHAT ELSE IS THERE TO DO?


module.exports = new TaskImplementation 'digimaps', {
  loadRawDataPrep
  loadRawData
  normalizeData
  recordChangeCounts
  finalizeDataPrep
  waitForExclusiveAccess
  finalizeData
  activateNewData: parcelHelpers.activateNewData
}
