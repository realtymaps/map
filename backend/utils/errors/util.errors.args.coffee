NamedError = require './util.error.named'

class InvalidArgumentError extends NamedError
  constructor: (args...) ->
    super('InvalidArgument', args...)

onMissingArgsFail = ({args, required, errorMsg}) ->
  for reqKey in required
    unless args[reqKey]?
      throw new InvalidArgumentError(errorMsg or "argument (#{reqKey}) is undefined and required")
  args

module.exports =
  InvalidArgumentError: InvalidArgumentError
  onMissingArgsFail: onMissingArgsFail
