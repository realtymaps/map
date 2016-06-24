logger = require('../config/logger').spawn("route:config")
auth = require '../utils/util.auth'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'
internals = require './route.config.internals'


handles = wrapHandleRoutes handles:

  safeConfig: (req, res, next) ->
    internals.safeConfigPromise()

  protectedConfig: (req, res, next) ->
    internals.protectedConfigPromise()

module.exports = mergeHandles handles,

  safeConfig: {}

  protectedConfig:
    middleware: auth.requireLogin(redirectOnFail: true)
