{taskHistory} = require '../services/service.jobs'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'

module.exports = mergeHandles routeCrud(taskHistory),
  root:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
