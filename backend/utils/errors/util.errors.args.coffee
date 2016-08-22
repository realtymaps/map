NamedError = require './util.error.named'
{arrayify} = require '../util.array'
_ = require 'lodash'

class InvalidArgumentError extends NamedError
  constructor: (args...) ->
    super('InvalidArgument', args...)

onMissingArgsFail = ({args, required, errorMsg, omit, quiet}) ->
  required = arrayify required
  for reqKey in required
    unless args[reqKey]?
      throw new InvalidArgumentError({quiet}, errorMsg or "argument (#{reqKey}) is undefined and required")
  if omit?
    args = _.omit args, omit
    # args = if _.isArray omit then _.omit args, omit else _.omit args, [omit]
  args

module.exports =
  InvalidArgumentError: InvalidArgumentError
  onMissingArgsFail: onMissingArgsFail
