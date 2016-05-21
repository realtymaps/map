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


NUM_ROWS_TO_PAGINATE = 2500
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

    # causes full refresh, see mls when we need to get more complicated
    deletes = dataLoadHelpers.DELETE.UNTOUCHED

    Promise.all [
      jobQueue.queueSubsequentSubtask {
        subtask
        manualData: filteredImports
        laterSubtaskName: 'loadRawData'
      }

      jobQueue.queueSubsequentSubtask {
        subtask, laterSubtaskName: "activateNewData"
        manualData: {deletes}
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
      # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
      # on whether this is a dump or an update)
      #TODO: the right way later
      Promise.all [
        jobQueue.queueSubsequentSubtask {
          subtask
          laterSubtaskName: "recordChangeCounts"
          #rawDataType fixes lookup of rawtable for change counts
          manualData: parcelHelpers.getRecordChangeCountsData(fipsCode)
          replace: true
        }

        jobQueue.queueSubsequentSubtask {
          subtask
          laterSubtaskName: "finalizeDataPrep"
          manualData: {fipsCode}
          replace: true
        }
      ]
      .then () ->
        numRawRows
    .then (numRows) ->
      if numRows == 0
        return
      logger.debug("num rows to normalize: #{numRows}")
      jobQueue.queueSubsequentPaginatedSubtask {
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

normalizeData = (subtask) ->
  logger.debug util.inspect(subtask, depth: null)

  {fipsCode,  delay} = subtask.data

  dataLoadHelpers.getRawRows subtask
  .then (rows) ->
    if !rows?.length
      logger.debug "no raw rows found for rm_raw_id #{subtask.data.offset+1} to #{subtask.data.offset+subtask.data.count}"
      return
    logger.debug "got #{rows.length} raw rows"

    parcelHelpers.saveToNormalDb {
      subtask
      rows
      fipsCode
      delay: delay ? DELAY_MILLISECONDS
    }

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
    ids  = ids.map (id) -> id.rm_property_id
    # ids = _.uniq(_.pluck(ids, 'rm_property_id')) #not needed as it is a primary_key at the moment
    jobQueue.queueSubsequentPaginatedSubtask(
      parcelHelpers.getFinalizeSubtaskData({subtask, ids, fipsCode, numRowsToPageFinalize})
    )

finalizeData = (subtask) ->
  logger.debug util.inspect(subtask, depth: null)

  {delay} = subtask.data

  Promise.map subtask.data.values, (id) ->
    parcelHelpers.finalizeData(subtask, id, delay ? DELAY_MILLISECONDS)
  # .then ->
  #   jobQueue.queueSubsequentSubtask {
  #     subtask,
  #     laterSubtaskName: 'syncCartoDb'
  #     manualData: subtask.data
  #     replace: true
  #   }

# syncCartoDb: (subtask) -> Promise.try ->
#   fipsCode = String.numeric path.basename subtask.task_data
#   parcel.upload(fipsCode)
#   .then ->
#     parcel.synchronize(fipsCode)
#     #WHAT ELSE IS THERE TO DO?


module.exports = new TaskImplementation {
  loadRawDataPrep
  loadRawData
  normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  finalizeDataPrep
  finalizeData
  activateNewData: parcelHelpers.activateNewData
}
