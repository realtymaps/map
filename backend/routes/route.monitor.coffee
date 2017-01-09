# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:monitor:error")
# coffeelint: enable=check_scope

module.exports =
  error:
    method: 'post'
    handle: (req, res, next) ->
      logger.debug req.body
      true
