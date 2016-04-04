Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../utils/util.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task.mls')
mlsHelpers = require './util.mlsHelpers'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
PromiseExt = require '../extensions/promise'

# NOTE: This file a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500

_pagenate = (subtask, taskName, ids, data) ->
  jobQueue.queueSubsequentPaginatedSubtask(null, subtask, ids, NUM_ROWS_TO_PAGINATE, taskName, data)

loadRawData = (subtask, pagenateFn = _pagenate) ->
  if subtask.data?.limit?
    limit = subtask.data?.limit
    logger.debug "limiting raw mls data to #{limit}"
    
  mlsHelpers.loadUpdates subtask,
    dataSourceId: subtask.task_name
    limit: limit
  .then ({numRawRows, deletes}) ->
    if numRawRows == 0
      return 0
    # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
    # on whether this is a dump or an update)
    recordCountsPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_recordChangeCounts", {deletes: deletes, dataType: 'listing'}, true)
    finalizePrepPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_finalizeDataPrep", null, true)
    storePhotosPrepPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_storePhotosPrep", null, true)
    activatePromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_activateNewData", {deletes: deletes}, true)
    Promise.join recordCountsPromise, finalizePrepPromise, storePhotosPrepPromise, activatePromise, () ->
      numRawRows
  .then pagenateFn.bind(null, subtask, "#{subtask.task_name}_normalizeData", dataType: 'listing')

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: subtask.task_name
    dataSourceType: 'mls'
    buildRecord: mlsHelpers.buildRecord

finalizeDataPrep = (subtask, pagenateFn = _pagenate) ->
  tables.property.listing()
  .select('rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
  .then pagenateFn.bind(null, subtask, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.finalizeData.bind(null, subtask)

storePhotosPrep = (subtask, pagenateFn = _pagenate) ->
  tables.property.combined()
  .select('id')
  .where(batch_id: subtask.batch_id)
  # .orderBy('id', 'desc')
  # .limit(1)
  .returning('id')
  .then (rows) ->
    r.id for r in rows
  .then pagenateFn.bind(null, subtask, "#{subtask.task_name}_storePhotos")

storePhotos = (subtask) -> Promise.try () ->
  #NOTE currently we can not do image download at high volume until we pool mls connections
  #swflmls, MRED and others only allow one connection at a time
  PromiseExt.reduceSeries subtask.data.values.map (id) -> ->
    mlsHelpers.storePhotos(subtask, id)
  # Promise.map subtask.data.values, mlsHelpers.storePhotos.bind(null, subtask)

module.exports = new TaskImplementation {
  loadRawData
  normalizeData
  finalizeDataPrep
  finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  storePhotosPrep
  storePhotos
}
