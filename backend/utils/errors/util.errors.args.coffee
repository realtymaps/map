_ = require 'lodash'
namedFactory = require './impl/util.error.impl.namedFactory'

errors = namedFactory [
  'InvalidArgument'
]
onMissingArgsFail = (argsObj) ->
  for key, obj of argsObj
    if obj?.required && !obj?.val
      throw new errors.InvalidArgumentError(obj.error or "argument (#{key}) is undefined and required")

module.exports = _.extend errors,
  onMissingArgsFail: onMissingArgsFail
