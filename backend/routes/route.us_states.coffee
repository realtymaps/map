auth = require '../utils/util.auth'
{us_states} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(us_states),
  #STRICTLY FOR ADMIN, otherwise profiles are used by session
  root:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  byId:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
