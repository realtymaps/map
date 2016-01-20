_ = require 'lodash'
generators = require './impl/util.error.impl.generators'
generatedErrors = generators.named [
  'IsIdObj'
  'MissingVar'
  'UpdateFailed'
]

PartiallyHandledError = require('./util.error.partiallyHandledError').PartiallyHandledError
class RouteCrudError extends PartiallyHandledError # used for ezcrud
  constructor: (args...) ->
    @name = 'CrudError'
    super(args...)

class ServiceCrudError extends PartiallyHandledError # used for ezcrud
  constructor: (args...) ->
    @name = 'ServiceError'
    super(args...)


module.exports =
  _.extend generatedErrors,
    RouteCrudError: RouteCrudError
    ServiceCrudError: ServiceCrudError
