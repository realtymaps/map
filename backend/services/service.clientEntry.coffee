_ = require 'lodash'
Promise = require 'bluebird'
keystoreSvc = require './service.keystore'
tables = require '../config/tables'
dbs = require '../config/dbs'
{transaction} = require '../config/dbs'
{expectSingleRow} = require '../utils/util.sql.helpers'
{createPasswordHash} =  require '../services/service.userSession'

_updateClient = (client) ->
  createPasswordHash client.password
  .then (password) ->
    client.password = password
    tables.auth.user().returning(['id','email','password']).update client
    .where id: client.id
    .then (client) ->
      console.log "client: #{JSON.stringify(client)}"
      client


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

setPasswordAndBounce = (client) ->
  console.log "client:\n#{JSON.stringify(client,null,2)}"
  _updateClient(client)
  # .then (id) ->


module.exports =
  getClientEntry: getClientEntry
  setPasswordAndBounce: setPasswordAndBounce
