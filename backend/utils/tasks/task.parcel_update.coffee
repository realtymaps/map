Promise =  require 'bluebird'
{uploadToParcelsDb} = require '../../services/service.parcels.saver'
{parcel} = require '../../services/service.cartodb'
db = require('../../config/dbs').properties

_subtasks =
    digimaps: (subtask ) ->
        fipsCode = subtask.data
        uploadToParcelsDb(fipsCode)

    sync_mv_parcels: (subtask) -> Promise.try ->
        db.knex.raw("SELECT stage_dirty_views();")
        .then ->
            db.knex.raw("SELECT push_staged_views(FALSE);")

    sync_cartodb: (subtask ) -> Promise.try ->
        fipsCode = subtask.data
        parcel.upload(fipsCode)
        .then ->
            parcel.synchronize(fipsCode)


module.exports =
  executeSubtask: (subtask) ->
      _subtasks[subtask.name](subtask)
