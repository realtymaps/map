_ = require 'lodash'
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

class RouteCrudError extends NamedError # used for ezcrud
  constructor: (args...) ->
    super('RouteCrudError', args...)

class ServiceCrudError extends NamedError # used for ezcrud
  constructor: (args...) ->
    super('ServiceCrudError', args...)

module.exports =
  IsIdObjError: IsIdObjError
  MissingVarError: MissingVarError
  UpdateFailedError: UpdateFailedError
  RouteCrudError: RouteCrudError
  ServiceCrudError: ServiceCrudError
