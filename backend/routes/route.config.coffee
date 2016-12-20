logger = require('../config/logger').spawn("route:config")
auth = require '../utils/util.auth'
internals = require './route.config.internals'

module.exports =
  safeConfig:
    handleQuery: true
    handle: (req, res, next) ->
      logger.debug "safeConfig handle"
      internals.safeConfigPromise()

  protectedConfig:
    handleQuery: true
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.protectedConfigPromise()
