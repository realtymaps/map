logger = require '../../config/logger'
{PartiallyHandledError, isUnhandled} = require '../errors/util.error.partiallyHandledError'
{singleRow} = require '../util.sql.helpers'
_ = require 'lodash'
factory = require '../util.factory'
BaseObject = require '../../../common/utils/util.baseObject'

logQuery = (q, doLogQuery) ->
  logger.debug(q.toString()) if doLogQuery

execQ = (q, doLogQuery) ->
  logQuery q, doLogQuery
  q

withSafeEntity = (entity, safe, cb, skipSafeError) ->
  if entity? and !safe
    throw new Error('safe must be defined if entity is defined') unless skipSafeError
  if entity? and safe?.length
    throw new Error('safe must be Array type') unless _.isArray safe
    entity = _.pick(entity, safe)
  cb(entity or {}, safe)

class Crud extends BaseObject
  constructor: (@dbFn, @idKey = 'id') ->
    super()
    unless _.isFunction @dbFn
      throw new Error('dbFn must be a knex function')
  idObj: (val) ->
    obj = {}
    obj[@idKey] = val
    obj

  getAll: (query = {}, doLogQuery = false, fnExec = execQ) ->
    fnExec @dbFn().where(query), doLogQuery

  getById: (id, doLogQuery = false, entity, safe, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @dbFn().where(_.extend @idObj(id), entity), doLogQuery

  update: (id, entity, safe, doLogQuery = false, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @dbFn().where(@idObj(id)).update(entity), doLogQuery
    , true

  create: (entity, id, doLogQuery = false, safe, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      # support entity or array of entities
      if _.isArray entity
        fnExec @dbFn().insert(entity), doLogQuery
      else
        obj = {}
        obj = @idObj id if id?
        fnExec @dbFn().insert(_.extend {}, entity, obj), doLogQuery
    , true

  delete: (id, doLogQuery = false, entity, safe, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @dbFn().where(_.extend @idObj(id), entity).delete(), doLogQuery

  base: () ->
    super([Crud,@].concat(_.toArray arguments)...)

class HasManyCrud extends Crud
  constructor: (dbFn, @rootCols, @joinCrud, joinIdStr, rootIdStr, idKey) ->
    super(dbFn, idKey)
    unless @joinCrud instanceof Crud
      throw new Error('@joinCrud must be Instance of Crud')
    @setIdStrs rootIdStr, joinIdStr

  joinQuery: () ->
    @joinCrud.dbFn()
    .select(@rootCols...)
    .innerJoin(@dbFn.tableName, @rootIdStr, @joinIdStr)

  setIdStrs: (rootIdStr,joinIdStr) ->
    @rootIdStr = rootIdStr or @dbFn.tableName + '.id'
    @joinIdStr = joinIdStr or @joinCrud.dbFn.tableName + ".#{@dbFn.tableName}_id"

  getAll: (entity, doLogQuery = false) ->
    if !_.isObject(entity) or !entity?
      throw new Error('entity must be defined or an Object.')
    execQ @joinQuery().where(entity), doLogQuery

  getById: (id, doLogQuery = false) ->
    execQ @joinQuery().where(@idObj(id)), doLogQuery

  create: (entity, id, doLogQuery = false) ->
    @joinCrud.create(entity, id, doLogQuery)

  update: (id, entity, safe, doLogQuery = false) ->
    @joinCrud.update(id, entity, safe, doLogQuery)

  delete: (id, doLogQuery = false) ->
    @joinCrud.delete(id, doLogQuery)

  base: () ->
    super([HasManyCrud,@].concat(_.toArray arguments)...)

###
NOTICE this really restricts how the crud is used!
Many times ThenableCrud should not even be instantiated until the
route layer where you know that you will definatley want a response totally in memory.
Many times returning the query itself is sufficent so it can be piped (MUCH better on memory)!
###
singleResultBoolean = (q, doRowCount) ->
  q.then (result) ->
    # logger.debug result
    unless doRowCount
      return result == 1
    result.rowCount == 1
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error)

thenables = [Crud, HasManyCrud].map (baseKlass) ->
  class ThenableTrait extends baseKlass
    constructor: ->
      super(arguments...)
      @init()

    init:(@doWrapGetAllThen = true, @doWrapGetThen = true) =>
      @
    #Majority of the time GETS are the main functions you might want to stream
    getAll: () =>
      q = super(arguments...)
      return q unless @doWrapGetAllThen

      q.then (data) ->
        data
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)

    getById: () ->
      q = super(arguments...)
      return q unless @doWrapGetThen
      singleRow q

    #here down return thenables to be consistent on service returns for single items
    update: () ->
      singleResultBoolean super(arguments...)

    create: () ->
      singleResultBoolean super(arguments...), true

    delete: () ->
      singleResultBoolean super(arguments...)


ThenableCrud = thenables[0]

ThenableHasManyCrud = thenables[1]

module.exports =
  Crud:Crud
  crud: factory Crud
  ThenableCrud: ThenableCrud
  thenableCrud: factory ThenableCrud
  HasManyCrud: HasManyCrud
  hasManyCrud: factory HasManyCrud
  ThenableHasManyCrud: ThenableHasManyCrud
  thenableHasManyCrud: factory ThenableHasManyCrud
  withSafeEntity:withSafeEntity
