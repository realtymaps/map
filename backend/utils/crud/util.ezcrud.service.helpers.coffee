logger = require('../../config/logger').spawn('backend:ezcrud.service')
BaseObject = require '../../../common/utils/util.baseObject'
isUnhandled = require('../errors/util.partiallyHandledError').isUnhandled
ServiceCrudError = require('../util.errors.crud').ServiceCrudError
_ = require 'lodash'
factory = require '../util.factory'

logger.debug "\n\n######## ezcrud service evaluated"


class Crud extends BaseObject
  constructor: (@dbFn, options = {}) ->
    # small one-liner for debug log func that respects debug option
    @debug = (msg) -> (options.debug ? false) and logger.debug "ServiceCrud: #{msg}"
    @returnKnex = options.returnKnex ? false
    @idKey = options.idKey ? 'id'
    unless _.isFunction @dbFn
      throw new ServiceCrudError('dbFn must be a knex function')
    @debug "Crud service instance made with options: #{options}"

  # In order to leverage centralized transaction handling (error catching etc) transactions
  #   should be routed through this helper method.
  # As things may grow on this class, this can hold any shared, central logic pertinent to the 'custom' scheme
  #   that we develop in the future
  custom: (transaction) ->
    @debug "Using custom transaction"
    @_wrapTransaction transaction

  # intermediate function to flag _wrapTransaction to return unevaluated knex
  exposeKnex: () ->
    @returnKnexTempFlag = true
    @debug "Flagged to return knex object"
    @

  # centralized handling, such as catching errors, for all queries including custom ones
  _wrapTransaction: (transaction) ->
    @debug transaction.toString()

    # return an objectified handle to knex obj if flagged
    if @returnKnex or @returnKnexTempFlag
      @returnKnexTempFlag = false
      return {knex: transaction} # exposes unevaluated knex

    # evaluate
    .then (result) ->
      @debug result
      result
    .catch isUnhandled, (error) ->
      @debug error
      throw new ServiceCrudError(error, "Error evaluating query: #{transaction}")

  getAll: (options = {}) ->
    @debug "getAll(), options=#{options}"
    @_wrapTransaction options.transaction ? @dbFn()

  create: (entity, options = {}) ->
    @debug "create(), entity=#{entity}, options=#{options}"
    @_wrapTransaction options.transaction ? @dbFn().returning(@idKey).insert(entity)

  getById: (id, entity, options = {}) ->
    @debug "getById(), id=#{id}, entity=#{entity}, options=#{options}"
    if options.transaction?
      return @_wrapTransaction options.transaction
    throw new ServiceCrudError("#{@dbFn.tableName}: #{idKey} is required") unless id?
    transaction = @dbFn().where("#{@idKey}": id)
    _.each entity, (val, key) ->
      if _.isArray val
        transaction = transaction.whereIn(key, val)
    transaction = transaction.where(_.omit(entity, _.isArray))
    @_wrapTransaction transaction

  update: (id, entity, options = {}) -> # safe = [] ?
    @debug "update(), id=#{id}, entity=#{entity}, options=#{options}"
    @_wrapTransaction options.transaction ? @dbFn.where("#{@idKey}": id).update(entity)

  upsert: (id, entity, options = {}) ->
    @debug "upsert(), id=#{id}, entity=#{entity}, options=#{options}"
    @_wrapTransaction options.transaction ? @dbFn.insert(_.extend {"#{@idkey}": id}, entity)

  delete: (id, entity, options = {}) ->
    @debug "delete(), id=#{id}, options=#{options}"
    @_wrapTransaction options.transaction ? @dbFn.where(_.extend {"#{@idkey}": id}, entity).delete()

  # base: () ->
  #   super([Crud,@].concat(_.toArray arguments)...)
###
NOTICE this really restricts how the crud is used!
Many times ThenableCrud should not even be instantiated until the
route layer where you know that you will definatley want a response totally in memory.
Many times returning the query itself is sufficent so it can be piped (MUCH better on memory)!
###
# singleResultBoolean = (q) ->
#   q.then (result) ->
#     unless doRowCount
#       return result == 1
#     result.rowCount == 1
#   .catch isUnhandled, (error) ->
#     throw new PartiallyHandledError(error)

# class ThenableCrud extends Crud
#   getAll: (doLogQuery = false) ->
#     super(doLogQuery)
#     .then (data) ->
#       data
#     .catch isUnhandled, (error) ->
#       throw new PartiallyHandledError(error)

#   getById: (id, doLogQuery = false) ->
#     singleRow super(id,doLogQuery)

#   #here down return thenables to be consistent on service returns for single items
#   update: (id, entity, safe = [], doLogQuery = false) ->
#     singleResultBoolean super(id, entity, safe, doLogQuery)

#   create: (entity, id, doLogQuery = false) ->
#     singleResultBoolean super(entity, id, doLogQuery), true

#   delete: (id, doLogQuery = false) ->
#     singleResultBoolean super(id, doLogQuery)

module.exports = Crud
  # Crud: Crud

  # ThenableCrud: ThenableCrud
  # thenableCrud: factory(ThenableCrud)