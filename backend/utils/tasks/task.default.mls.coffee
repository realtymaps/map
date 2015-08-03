Promise = require "bluebird"
mlsHelpers = require '../util.mlsHelpers'
jobQueue = require '../util.jobQueue'
dbs = require '../../config/dbs'
tables = require '../../config/tables'
util = require 'util'
logger = require '../../config/logger'


# NOTE: This file is actually going to go away.  We don't want to have an explicit task file for each of the hundreds
# of MLSs.  So this code will turn into default subtask handlers for mls update tasks, which can be overridden by
# explicitly providing a file like this (if we find an edge case that doesn't obey the rules).


NUM_ROWS_TO_PAGINATE = 500


loadDataRawMain = (subtask) ->
  mlsHelpers.loadRetsTableUpdates subtask,
    rawTableSuffix: 'main'
    retsDbName: 'Property'
    retsTableName: 'RES'
    retsQueryTemplate: "[(LastChangeTimestamp=]YYYY-MM-DD[T]HH:mm:ss[+),(ListingOnInternetYN=1)]"
    retsId: subtask.task_name
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, numRows, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_normalizeData")

normalizeData = (subtask) ->
  mlsHelpers.normalizeData subtask,
    rawTableSuffix: 'main'
    dataSourceId: subtask.task_name

finalizeDataPrep = (subtask) ->
  # slightly hackish raw query needed for count(distinct blah):
  # https://github.com/tgriesser/knex/issues/238
  tables.propertyData.mls()
  .select(dbs.properties.knex.raw('count(distinct "rm_property_id")'))
  .where(batch_id: subtask.batch_id)
  .then (info) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, info[0].count, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  tables.propertyData.mls()
  .distinct('rm_property_id')
  .select()
  .where(batch_id: subtask.batch_id)
  .orderBy('rm_property_id')
  .offset(subtask.data.offset)
  .limit(subtask.data.count)
  .then (ids) ->
    Promise.map ids, mlsHelpers.finalizeData.bind(null, subtask)
      

subtasks =
  loadDataRawMain: loadDataRawMain
  normalizeData: normalizeData
  recordChangeCounts: mlsHelpers.recordChangeCounts
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: mlsHelpers.activateNewData

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name.replace(/[^_]+_/g,'')](subtask)
