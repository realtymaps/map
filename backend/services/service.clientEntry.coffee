_ = require 'lodash'
Promise = require 'bluebird'
keystoreSvc = require './service.keystore'
tables = require '../config/tables'
dbs = require '../config/dbs'
{transaction} = require '../config/dbs'
{expectSingleRow} = require '../utils/util.sql.helpers'
{createPasswordHash} =  require '../services/service.userSession'

_updateClient = (client) ->
  # TODO:  handle if client already exists
  createPasswordHash client.password
  .then (password) ->
    # make the client user suitable for login
    tables.auth.user().returning(['id','email','password']).update(
      password: password
      email_is_valid: true
      is_active: true)
    .where id: client.id
    .then (savedClient) ->
      # return original client for login to use original form
      client

getClientEntry = (key) ->
  dbs.transaction 'main', (trx) ->
    # user/project data was saved in value for this client-entry key
    keystoreSvc.getValue key, namespace: 'client-entry', transaction: trx
    .then (entry) ->
      # get the user & parent objs
      tables.auth.user transaction: trx
      .select 'id', 'email', 'first_name', 'last_name'
      .whereIn 'id', [entry.user.id, entry.user.parent_id]
      .then (users) ->
        # "keyBy" the users for better referencing later
        authUsers = {}
        for user in users
          authUsers[user.id] = user
        authUsers
      .then (authUsers) ->
        # obtain helpful project members
        tables.user.project transaction: trx
        .select 'id', 'name', 'sandbox'
        .where id: entry.project.id
        .then (project) ->
          expectSingleRow project
        .then (project) ->
          {
            event: entry.event.name # helps frontend distinguish new user
            client: authUsers[entry.user.id]
            parent: authUsers[entry.user.parent_id]
            project: project
          }

# sets password (if applicable) then logs client in to map
setPasswordAndBounce = (client) ->
  _updateClient(client)


module.exports =
  getClientEntry: getClientEntry
  setPasswordAndBounce: setPasswordAndBounce
