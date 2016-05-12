_ = require 'lodash'
Promise = require 'bluebird'
keystoreSvc = require './service.keystore'
tables = require '../config/tables'
dbs = require '../config/dbs'
{expectSingleRow} = require '../utils/util.sql.helpers'


getClientEntry = (key) ->
  dbs.transaction 'main', (trx) ->
    keystoreSvc.getValue key, namespace: 'client-entry', transaction: trx
    .then (entry) ->
      console.log "entry:\n#{JSON.stringify(entry,null,2)}"
      tables.auth.user transaction: trx
      .select 'id', 'email', 'first_name', 'last_name'
      .whereIn 'id', [entry.auth_user_id, entry.parent_auth_user_id]
      .then (users) ->
        console.log "users:\n#{JSON.stringify(users,null,2)}"
        authUsers = {}
        for user in users
          authUsers[user.id] = user
        authUsers
      .then (authUsers) ->
        tables.user.project transaction: trx
        .select 'id', 'name', 'sandbox'
        .where id: entry.project_id
        .then (project) ->
          expectSingleRow project
        .then (project) ->
          console.log "authUsers:\n#{JSON.stringify(authUsers,null,2)}"
          console.log "project:\n#{JSON.stringify(project,null,2)}"
          {
            client: authUsers[entry.auth_user_id]
            parent: authUsers[entry.parent_auth_user_id]
            project: project
          }

module.exports =
  getClientEntry: getClientEntry
