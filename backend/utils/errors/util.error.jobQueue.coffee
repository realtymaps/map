NamedError = require('./util.error.named')

class SoftFail extends NamedError
  constructor: (args...) ->
    @quiet = true
    super('SoftFail', args...)

class HardFail extends NamedError
  constructor: (args...) ->
    @quiet = true
    super('HardFail', args...)

class TaskNotImplemented extends NamedError
  constructor: (args...) ->
    @quiet = true
    super('TaskNotImplemented', args...)

module.exports =
  SoftFail: SoftFail
  HardFail: HardFail
  TaskNotImplemented: TaskNotImplemented
