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
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail} = require '../utils/errors/util.error.jobQueue'


HALF_YEAR_MILLISEC = moment.duration(year:1).asMilliseconds() / 2
NUM_ROWS_TO_PAGINATE = 2500

_filterImports = (subtask, imports) ->
  dataLoadHelpers.refreshThreshold subtask,
    fullRefreshMilliSec: HALF_YEAR_MILLISEC
    logDescription: 'task.mls'
  .then (refreshThreshold) ->
    folderObjs = imports.map (l) ->
      name: l
      moment: moment(String.numeric(l), 'YYYYMMDD').utc()

    folderObjs = _.filter folderObjs, (o) ->
      o.moment.isAfter(moment(refreshThreshold).utc())

    filteredImports: folderObjs.map (f) -> f.name
    refreshThreshold: refreshThreshold


loadRawDataPrep = (subtask) -> Promise.try () ->
  logger.debug subtask

  externalAccounts.getAccountInfo(subtask.task_name)
  .then (creds) ->
    parcelsFetch.defineImports({creds})
  .then (imports) ->
    _filterImports(subtask, imports)
  .then ({filteredImports, refreshThreshold}) ->
    # filteredImports = [filteredImports[0]] #NOTE: for testing ONLY

    filteredImports = filteredImports.map (f) ->
      fileName: f
      refreshThreshold: refreshThreshold

    jobQueue.queueSubsequentSubtask({ subtask, manualData: filteredImports, laterSubtaskName: 'loadRawData'})

loadRawData = (subtask) -> Promise.try () ->
  logger.debug subtask

  {fileName, refreshThreshold} = subtask.data
  fipsCode = String.numeric path.basename fileName

  externalAccounts.getAccountInfo(subtask.task_name)
  .then (creds) ->
    parcelsFetch.getParcelJsonStream(fileName, {creds})
    .then (jsonStream) ->
      rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask)) + '_' + fipsCode
      dataLoadHistory =
        data_source_id: "#{subtask.task_name}_#{fileName}"
        data_source_type: 'parcel'
        data_type: 'parcel'
        batch_id: subtask.batch_id
        raw_table_name: rawTableName

      dataLoadHelpers.manageRawJSONStream({
        tableName: rawTableName
        dataLoadHistory
        jsonStream
        columns: 'feature'
        strTranforms: JSON.stringify
      })
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
      .catch (error) ->
        throw new SoftFail error.message
    .then (numRawRows) ->
      deletes = if (new Date(refreshThreshold)).getTime() == 0 then dataLoadHelpers.DELETE.UNTOUCHED else dataLoadHelpers.DELETE.NONE
      {numRawRows, deletes}
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'failed to load parcels data for update')
    .catch (error) ->
      msg = logger.maybeInvalidError {error, where: 'parcels:loadRawData'}
      throw SoftFail msg
    .then ({numRawRows, deletes}) ->
      if numRawRows == 0
        return 0
      # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
      # on whether this is a dump or an update)
      #TODO: the right way later
      recordCountsPromise = jobQueue.queueSubsequentSubtask {
        subtask
        laterSubtaskName: "recordChangeCounts"
        #rawDataType fixes lookup of rawtable for change counts
        manualData: {deletes, dataType:"normParcel", rawDataType:"parcel"}
        replace: true
      }
      finalizePrepPromise = jobQueue.queueSubsequentSubtask {
        subtask
        laterSubtaskName: "finalizeDataPrep"
        replace: true
      }
      activatePromise = jobQueue.queueSubsequentSubtask {
        subtask, laterSubtaskName: "activateNewData"
        manualData: {deletes}
        replace: true
      }
      #finalizePrepPromise, activatePromise #ADD TO JOIN
      Promise.join recordCountsPromise, finalizePrepPromise, activatePromise,  () ->
        numRawRows
    .then (numRows) ->
      if numRows == 0
        return
      logger.debug("num rows to normalize: #{numRows}")
      jobQueue.queueSubsequentPaginatedSubtask {
        subtask, totalOrList: numRows
        maxPage: NUM_ROWS_TO_PAGINATE
        laterSubtaskName: "normalizeData"
        mergeData: {fipsCode}
      }

normalizeData = (subtask) ->
  logger.debug subtask

  {fipsCode} = subtask.data

  logger.debug subtask.data

  rawSubid = dataLoadHelpers.buildUniqueSubtaskName(subtask) + '_' + fipsCode

  dataLoadHelpers.getNormalizeRows(subtask, rawSubid)
  .then (rows) ->
    return if !rows?.length

    parcelHelpers.saveToNormalDb {
      subtask
      rows
      fipsCode
    }

finalizeDataPrep = (subtask) ->
  logger.debug subtask

  tables.property.normParcel()
  .select('rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    ids  = ids.map (id) -> id.rm_property_id
    # ids = _.uniq(_.pluck(ids, 'rm_property_id')) #not needed as it is a primary_key at the moment
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: NUM_ROWS_TO_PAGINATE, laterSubtaskName: "finalizeData"})

finalizeData = (subtask) ->
  logger.debug subtask

  Promise.map subtask.data.values, (id) ->
    parcelHelpers.finalizeData(subtask, id)
  .then ->
    jobQueue.queueSubsequentSubtask {
      subtask,
      laterSubtaskName: 'syncCartoDb'
      manualData: subtask.data
      replace: true
    }

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
