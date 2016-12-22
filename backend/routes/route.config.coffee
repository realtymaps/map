logger = require('../config/logger').spawn("route:config")
internals = require './route.config.internals'

module.exports =
  safeConfig:
    handleQuery: true
    handle: (req, res, next) ->
      logger.debug "safeConfig handle"
      internals.safeConfigPromise()
