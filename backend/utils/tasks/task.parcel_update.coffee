Promise =  require 'bluebird'
{uploadToParcelsDb} = require '../../services/service.parcels.saver'
{parcel} = require '../../services/service.cartodb'
db = require('../../config/dbs').properties
Encryptor = require '../util.encryptor'
encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)


_subtasks =
    ###
    To define an import in digimaps_parcel_imports we need to get folderNames and fipsCodes

    - 1 First we need to get alll directories that are not imported_time
      - listAsync all DELIVERY_ ..folderNames
      - then get all imported fodlerNames to remove drom the all listed
    - 2 then get all fipsCodes for all the non imported folderNames
       - traverse into Zips and listAsync all files and parse all fipsCodes
    - 3 then insert each object into digimaps_parcel_imports
    ###
    digimaps_define_imports : _defineImports

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
