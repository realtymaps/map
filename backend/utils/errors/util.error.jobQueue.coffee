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

class TaskStartError extends NamedError
  constructor: (args...) ->
    @quiet = true
    @expected = true
    super('TaskStartError', args...)

class LockError extends NamedError
  constructor: (args...) ->
    @quiet = true
    super('LockError', args...)

module.exports = {
  SoftFail
  HardFail
  TaskNotImplemented
  LockError
  TaskStartError
}
