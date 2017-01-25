partial = require('./util.error.partiallyHandledError')
httpStatus = require '../../../common/utils/httpStatus'
logger = require('../../config/logger').spawn("util:error:profile")

class CurrentProfileError extends partial.PartiallyHandledError
  constructor: (args...) ->
    super('CurrentProfileError', args...)
    @returnStatus = httpStatus.BAD_REQUEST

class NoProfileFoundError extends partial.PartiallyHandledError
  @handle = (req) -> (error) ->
    auth = require '../util.auth'
    logger.debug -> 'Logging out due to zero profiles.'

    auth.logout(req, null, false).then ->
      error.expected = true
      error.quiet = true
      throw error #rethow to send bad http status


  constructor: (args...) ->
    super('NoProfileFoundError', args...)
    @returnStatus = httpStatus.UNAUTHORIZED


module.exports = {
  CurrentProfileError
  NoProfileFoundError
}
