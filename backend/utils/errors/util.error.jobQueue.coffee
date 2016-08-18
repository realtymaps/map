NamedError = require('./util.error.named')

class SoftFail extends NamedError
  constructor: (args...) ->
    super('SoftFail', {quiet: true}, args...)

class HardFail extends NamedError
  constructor: (args...) ->
    super('HardFail', {quiet: true}, args...)

class TaskNotImplemented extends NamedError
  constructor: (args...) ->
    super('TaskNotImplemented', {quiet: true}, args...)

module.exports =
  SoftFail: SoftFail
  HardFail: HardFail
  TaskNotImplemented: TaskNotImplemented
