# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:monitor:error")
Promise = require 'bluebird'
# coffeelint: enable=check_scope

module.exports =
  error:
    method: 'post'
    handleQuery: true
    handle: (req, res, next) ->
      logger.debug req.body
      Promise.resolve true
