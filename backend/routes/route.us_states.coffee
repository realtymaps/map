auth = require '../utils/util.auth'
{usStates} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(usStates),
  root:
    middleware: []
  byId:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
