Promise = require 'bluebird'
{uploadToParcelsDb} = require '../services/service.parcels.saver'
{parcel} = require '../services/service.cartodb'
jobQueue = require '../utils/util.jobQueue'
_ = require 'lodash'
tables = require '../config/tables'
dbs = require '../config/dbs'
externalAccounts =  require '../services/service.externalAccounts'


_subtasks =
  digimaps_define_imports: (subtask) ->
    externalAccounts.getAccountInfo('digimaps')
    .then (creds) ->
      _defineImports(subtask, creds)
    .then (imports) ->
      fileToDownload = imports.map (f) -> f.source_id
      jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: 'digimaps_save', manualData: fileToDownload, replace: true})

  digimaps_save: (subtask) ->
    #all saving and upserting is handled in this function
    #is data_load_history row considered in-progress if inserted_rows, updated_rows, deleted_rows, and invalid_rows are all null
    #should there not be a column to indicate that imports have started for this history item?
    externalAccounts.getAccountInfo('digimaps')
    .then (creds) ->
      uploadToParcelsDb(subtask.data, creds)
    .then ({invalidCtr, insertsCtr, updatesCtr}) ->
      tables.jobQueue.dataLoadHistory()
      .update
        inserted_rows: insertsCtr
        updated_rows: updatesCtr
        invalid_rows: invalidCtr
      .where
        batch_id: subtask.batch_id
        data_source_type: 'parcels'
        data_source_id: subtask.data
    .then ->
      jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: 'sync_mv_parcels', manualData: subtask.data, replace: true})

  sync_mv_parcels: (subtask) -> Promise.try ->
    dbs.get('main').raw('SELECT stage_dirty_views();')
    .then ->
      dbs.get('main').raw('SELECT push_staged_views(FALSE);')
    .then ->
      jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: 'sync_cartodb', manualData: subtask.data, replace: true})

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
