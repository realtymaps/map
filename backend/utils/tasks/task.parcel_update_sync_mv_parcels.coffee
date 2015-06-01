db = require('../../config/dbs').properties
Promise = require 'bluebird'

module.exports =
  executeSubtask: (subtask) -> Promise.try () ->
    db.knex.raw("SELECT stage_dirty_views();")
    .then ->
        db.knex.raw("SELECT push_staged_views(FALSE);")
