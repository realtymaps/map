NamedError = require('./util.error.named')
httpStatus = require '../../../common/utils/httpStatus'

class ExpectedSingleRowError extends NamedError
  constructor: (args...) ->
    super('ExpectedSingleRowError', args...)
    @returnStatus = httpStatus.NOT_FOUND


module.exports = ExpectedSingleRowError
