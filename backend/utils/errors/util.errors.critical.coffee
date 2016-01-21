NamedError = require './util.error.named'

class CriticalError extends NamedError
  constructor: (args...) ->
    super('Critical', args...)

class InitCriticalError extends NamedError
  constructor: (args...) ->
    super('InitCritical', args...)

module.exports =
  CriticalError:CriticalError
  InitCriticalError: InitCriticalError
