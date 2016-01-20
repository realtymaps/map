logger = require('../../config/logger').spawn("backend:ezcrud")
BaseObject = require '../../../common/utils/util.baseObject'
isUnhandled = require('../errors/util.partiallyHandledError').isUnhandled
ServiceCrudError = require('../util.errors.crud').ServiceCrudError
{singleRow} = require '../util.sql.helpers'
_ = require 'lodash'
factory = require '../util.factory'

logger.debug "\n\n######## ezcrud service evaluated"

# logQuery = (q, doLogQuery) ->
#   logger.debug(q.toString()) if doLogQuery

# execQ = (q, doLogQuery) ->
#   logQuery q, doLogQuery
#   q

class Crud extends BaseObject
  constructor: (@dbFn, @idKey = 'id', options = {}) ->
    # small one-liner for debug log func that respects debug option
    @debug = (msg) -> (options.debug ? false) and logger.debug "#{msg}"
    @returnKnex = options.returnKnex ? false
    unless _.isFunction @dbFn
      throw new ServiceCrudError('dbFn must be a knex function')
    @debug "Crud service instance made with options: #{options}"

  knex: () ->
    @returnKnex = true
    @debug "Set to return knex object"
    @

  _wrapTransaction: (transaction) ->
    @debug transaction.toString()
    if @returnKnex then transaction else transaction
    .then (result) ->
      @debug result
      result
    .catch isUnhandled, (error) ->
      @debug error
      throw new ServiceCrudError(error, "Error evaluating query: #{transaction}")

  getAll: () ->
    @debug "getAll()"
    _wrapTransaction @dbFn()
    #execQ @dbFn()

  create: (entity) ->
    _wrapTransaction @dbFn().returning(@idKey).insert(entity)

  getById: (id, entity) ->
    throw new ServiceCrudError("#{@dbFn.tableName}: #{idKey} is required") unless id?
    where = @dbFn()
    _.each entity, (val, key) ->
      if _.isArray val
        where = where.whereIn(key, val)
    where = where.where(_.omit(query, _.isArray))
    _wrapTransaction where
    # execQ @dbFn().where(id: id)

  #here down return thenables to be consistent on service returns for single items
  update: (id, entity) -> # safe = [] ?
    @debug "update(), id: #{id}, entity: #{entity}"
    _wrapTransaction @dbFn.where("#{@idKey}": id).update(entity)

  upsert: (id, entity) ->
    @debug "upsert(), id: #{id}, entity: #{entity}"
    _wrapTransaction @dbFn.insert(_.extend {"#{@idkey}": id}, entity) # 

  delete: (id) ->
    @debug "delete(), id: #{id}"
    _wrapTransaction @dbFn.where(id: id).delete()

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

module.exports =
  Crud: Crud
  crud: factory(Crud)
  # ThenableCrud: ThenableCrud
  # thenableCrud: factory(ThenableCrud)