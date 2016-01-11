_ = require 'lodash'
namedFactory = require './impl/util.error.impl.namedFactory'

errors = namedFactory [
  'InvalidArgument'
]
onMissingArgsFail = (argsObj) ->
  for key, val of argsObj
    if val?.required && !val
      throw new errors.InvalidArgumentError(val.error or "argument (#{key}) is undefined and required")

module.exports = _.extend errors,
  onMissingArgsFail: onMissingArgsFail
