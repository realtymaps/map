_ = require 'lodash'
NamedError = require './util.error.named'
PartiallyHandledError = require('./util.error.partiallyHandledError').PartiallyHandledError

class IsIdObjError extends NamedError
  constructor: (args...) ->
    super('IsIdObj', args...)

class MissingVarError extends NamedError
  constructor: (args...) ->
    super('MissingVar', args...)

class UpdateFailedError extends NamedError
  constructor: (args...) ->
    super('UpdateFailed', args...)

class RouteCrudError extends PartiallyHandledError # used for ezcrud
  constructor: (args...) ->
    @name = 'RouteCrudError'
    super(args...)

class ServiceCrudError extends PartiallyHandledError # used for ezcrud
  constructor: (args...) ->
    @name = 'ServiceCrudError'
    super(args...)

module.exports =
  IsIdObjError: IsIdObjError
  MissingVarError: MissingVarError
  UpdateFailedError: UpdateFailedError
  RouteCrudError: RouteCrudError
  ServiceCrudError: ServiceCrudError