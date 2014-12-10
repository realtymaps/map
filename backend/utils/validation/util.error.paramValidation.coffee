analyzeValue = require '../../../common/utils/util.analyzeValue'

class ParamValidationError extends Error
  constructor: (@message, @paramName, @paramValue) ->
    @name = "ParamValidationError"
    Error.captureStackTrace(this, ParamValidationError)
    analysis = analyzeValue(@paramValue)
    @message = "error validating param <#{@paramName}> with value <#{analysis.type}"+(if analysis.details then ": #{analysis.details}" else "")+"> (#{@message})"

module.exports = ParamValidationError
