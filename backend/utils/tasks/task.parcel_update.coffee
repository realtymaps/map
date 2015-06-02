Promise =  require 'bluebird'
{uploadToParcelsDb} = require '../../services/service.parcels.saver'
{parcel} = require '../../services/service.cartodb'
db = require('../../config/dbs').properties
Encryptor = require '../util.encryptor'
encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)

_subtasks =
    digimaps: (subtask) ->
        taskData = JSON.parse subtask.task_data
        for k, val of taskData.DIGIMAPS
            taskData.DIGIMAPS[k] = encryptor.decrypt(val)
        uploadToParcelsDb(taskData.fipsCode[0], taskData.DIGIMAPS)

    sync_mv_parcels: (subtask) -> Promise.try ->
        db.knex.raw("SELECT stage_dirty_views();")
        .then ->
            db.knex.raw("SELECT push_staged_views(FALSE);")

    sync_cartodb: (subtask ) -> Promise.try ->
        taskData = JSON.parse subtask.task_data
        fipsCode = taskData.fipsCodes[0]
        parcel.upload(fipsCode)
        .then ->
            parcel.synchronize(fipsCode)
            #on successful run should taskData.fipsCodes be shifted and updated from here?
            #or is this done somewhere at a higher level?


module.exports =
  executeSubtask: (subtask) ->
      _subtasks[subtask.name](subtask)
