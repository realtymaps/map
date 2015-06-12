Promise =  require 'bluebird'
{uploadToParcelsDb} = require '../../services/service.parcels.saver'
{parcel} = require '../../services/service.cartodb'
db = require('../../config/dbs').properties
Encryptor = require '../util.encryptor'
encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)
jobQueue = require '../util.jobQueue'
_ = require 'lodash'
taskHelpers = require '../utils/tasks/util.taskHelpers'


_getCreds: (subtask) ->
    taskData = JSON.parse subtask.task_data
    for k, val of taskData.DIGIMAPS
        taskData.DIGIMAPS[k] = encryptor.decrypt(val)
    taskData.DIGIMAPS

_subtasks =
    digimaps_define_imports : (subtask) ->
        _defineImports(subtask, _getCreds(subtask))
        .then (imports) ->
            fileToDownload = imports.map (f) -> f.source_id
            jobQueue.queueSubsequentSubtask jobQueue.knex, subtask, 'digimaps_save' ,fileToDownload, true

    digimaps_save: (subtask) ->
        #all saving and upserting is handled in this function
        #is data_load_history row considered in-progress if inserted_rows, updated_rows, deleted_rows, and invalid_rows are all null
        #should there not be a column to indicate that imports have started for this history item?
        uploadToParcelsDb(subtask.data, _getCreds(subtask))
        .then ({invalidCtr, insertsCtr, updatesCtr}) ->
            taskHelpers.queries.dataHistory()
            .update
                inserted_rows: insertsCtr
                updated_rows: updatesCtr
                invalid_rows: invalidCtr
            .where
                batch_id: subtask.batch_id
                data_source_type: 'parcels'
                data_source_id: subtask.data
        .then ->
            jobQueue.queueSubsequentSubtask jobQueue.knex, subtask, 'sync_mv_parcels', subtask.data, true

    sync_mv_parcels: (subtask) -> Promise.try ->
        db.knex.raw("SELECT stage_dirty_views();")
        .then ->
            db.knex.raw("SELECT push_staged_views(FALSE);")
        .then ->
            jobQueue.queueSubsequentSubtask jobQueue.knex, subtask, 'sync_cartodb', subtask.data, true

    sync_cartodb: (subtask) -> Promise.try ->
        fileName = _.last subtask.task_data.split('/')
        fipsCode = fileName.replace(/\D/g, '')
        parcel.upload(fipsCode)
        .then ->
            parcel.synchronize(fipsCode)
        #WHAT ELSE IS THERE TO DO?


module.exports =
  executeSubtask: (subtask) ->
      _subtasks[subtask.name](subtask)
