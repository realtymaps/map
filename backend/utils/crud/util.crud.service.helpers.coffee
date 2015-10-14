logger = require '../../config/logger'
{PartiallyHandledError, isUnhandled} = require '../util.partiallyHandledError'
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

  getAll: (query = {}, safe, doLogQuery = false, fnExec = execQ) ->
    withSafeEntity query, safe, (query, safe) =>
      fnExec @dbFn().where(query), doLogQuery
    , true

  getById: (id, doLogQuery = false, fnExec = execQ) ->
    throw new Error('id is required') unless id?
    fnExec @dbFn().where(@idObj(id)), doLogQuery

  update: (id, entity, safe, doLogQuery = false, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @dbFn().where(@idObj(id)).update(entity), doLogQuery
    , true

  create: (id, entity, safe, doLogQuery = false, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      # support entity or array of entities
      if _.isArray entity
        fnExec @dbFn().insert(entity), doLogQuery
      else
        obj = {}
        obj = @idObj id if id?
        fnExec @dbFn().insert(_.extend {}, entity, obj), doLogQuery
    , true

  delete: (id, doLogQuery = false, fnExec = execQ) ->
    throw new Error('id is required') unless id?
    fnExec @dbFn().where(@idObj(id)).delete(), doLogQuery

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

  setIdStrs: (rootIdStr, joinIdStr) ->
    @rootIdStr = rootIdStr or @dbFn.tableName + '.id'
    @joinIdStr = joinIdStr or @joinCrud.dbFn.tableName + ".#{@dbFn.tableName}_id"

  getAll: (query, safe, doLogQuery = false) ->
    withSafeEntity query, safe, (query, safe) =>
      execQ @joinQuery().where(query), doLogQuery
    , true

  getById: (id, doLogQuery = false) ->
    throw new Error('id is required') unless id?
    execQ @joinQuery().where(@idObj(id)), doLogQuery

  create: (id, entity, safe, doLogQuery = false) ->
    @joinCrud.create(id, entity, safe, doLogQuery)

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
