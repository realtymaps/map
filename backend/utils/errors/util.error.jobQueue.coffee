NamedError = require('./util.error.named')

class SoftFail extends NamedError
  constructor: (args...) ->
    super('SoftFail', args...)

class HardFail extends NamedError
  constructor: (args...) ->
    super('HardFail', args...)

class TaskNotImplemented extends NamedError
  constructor: (args...) ->
    super('TaskNotImplemented', args...)

module.exports =
  SoftFail: SoftFail
  HardFail: HardFail
  TaskNotImplemented: TaskNotImplemented
