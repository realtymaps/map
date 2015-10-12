PartiallyHandledError = require('./util.error.partiallyHandledError').PartiallyHandledError


class SoftFail extends PartiallyHandledError
  constructor: (args...) ->
    super(args...)
    @name = 'SoftFail'

class HardFail extends PartiallyHandledError
  constructor: (args...) ->
    super(args...)
    @name = 'HardFail'


module.exports =
  SoftFail: SoftFail
  HardFail: HardFail
