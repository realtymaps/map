analyzeValue = require '../../../common/utils/util.analyzeValue'

class DataValidationError extends Error
  constructor: (@message, @paramName, @paramValue) ->
    @name = "DataValidationError"
    Error.captureStackTrace(this, DataValidationError)
    analysis = analyzeValue(@paramValue)
    @message = "error validating param <#{@paramName}> with value <#{analysis.type}"+(if analysis.details then ": #{analysis.details}" else '')+"> (#{@message})"

module.exports = DataValidationError
