NamedError = require './util.error.named'

class InvalidArgumentError extends NamedError
  constructor: (args...) ->
    super('InvalidArgument', args...)

onMissingArgsFail = (argsObj) ->
  for key, obj of argsObj
    if obj?.required && !obj?.val?
      throw new InvalidArgumentError(obj.error or "argument (#{key}) is undefined and required")

module.exports =
  InvalidArgumentError: InvalidArgumentError
  onMissingArgsFail: onMissingArgsFail
