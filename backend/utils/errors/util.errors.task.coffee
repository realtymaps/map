NamedError = require('./util.error.named')

class TaskNameError extends NamedError
  constructor: (args...) ->
    super('TaskNameError', args...)

class MissingSubtaskError extends NamedError
  constructor: (args...) ->
    super('MissingSubtaskError', args...)

module.exports = {
  TaskNameError
  MissingSubtaskError
}
