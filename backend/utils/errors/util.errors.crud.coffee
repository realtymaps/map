NamedError = require './util.error.named'

class IsIdObjError extends NamedError
  constructor: (args...) ->
    super('IsIdObj', args...)

class MissingVarError extends NamedError
  constructor: (args...) ->
    super('MissingVar', args...)

class UpdateFailedError extends NamedError
  constructor: (args...) ->
    super('UpdateFailed', args...)

module.exports =
  IsIdObjError:IsIdObjError
  MissingVarError: MissingVarError
  UpdateFailedError: UpdateFailedError
