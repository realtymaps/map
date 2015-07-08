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

class Crud extends BaseObject
  constructor: (@dbFn, @idKey = "id") ->
    super()
    unless _.isFunction @dbFn
      throw 'dbFn must be a knex function'
  idObj: (val) ->
    obj = {}
    obj[@idKey] = val
    obj

  getAll: (doLogQuery = false) ->
    execQ @dbFn(), doLogQuery

  getById: (id, doLogQuery = false) ->
    execQ @dbFn().where(@idObj(id)), doLogQuery

  update: (id, entity, safe = [], doLogQuery = false) ->
    execQ @dbFn().where(@idObj(id)).update _.pick(entity, safe), doLogQuery

  create: (entity, id, doLogQuery = false) ->
    obj = {}
    obj = @idObj id if id?
    execQ @dbFn().insert(_.extend {}, entity, obj), doLogQuery

  delete: (id, doLogQuery = false) ->
    execQ @dbFn().where(@idObj(id)).delete(), doLogQuery

  base: () ->
    super([Crud,@].concat(_.toArray arguments)...)

class HasManyCrud extends Crud
  constructor: (dbFn, @rootCols, @joinCrud, joinIdStr, rootIdStr, idKey) ->
    super(dbFn, idKey)
    unless @joinCrud instanceof Crud
      throw "@joinCrud must be Instance of Crud"
    @setIdStrs rootIdStr, joinIdStr

  joinQuery: () ->
    @joinCrud.dbFn()
    .select(@rootCols...)
    .innerJoin(@dbFn.tableName, @rootIdStr, @joinIdStr)

  setIdStrs: (rootIdStr,joinIdStr) ->
    @rootIdStr = rootIdStr or @dbFn.tableName + ".id"
    @joinIdStr = joinIdStr or @joinCrud.dbFn.tableName + ".#{@dbFn.tableName}_id"

  getAll: (entity, doLogQuery = false) ->
    execQ @joinQuery().where(entity), doLogQuery

  getById: (id, doLogQuery = false) ->
    execQ @joinQuery().where(@idObj(id)), doLogQuery

  create: (entity, id, doLogQuery = false) ->
    @joinCrud.create(entity, id, doLogQuery)

  update: (id, entity, safe = [], doLogQuery = false) ->
    @joinCrud(id, entity, safe, doLogQuery)

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
    unless doRowCount
      return result == 1
    result.rowCount == 1
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error)

class ThenableCrud extends Crud
  getAll: (doLogQuery = false) ->
    super(doLogQuery)
    .then (data) ->
      data
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  getById: (id, doLogQuery = false) ->
    singleRow super(id,doLogQuery)

  #here down return thenables to be consistent on service returns for single items
  update: (id, entity, safe = [], doLogQuery = false) ->
    singleResultBoolean super(id, entity, safe, doLogQuery)

  create: (entity, id, doLogQuery = false) ->
    singleResultBoolean super(entity, id, doLogQuery), true

  delete: (id, doLogQuery = false) ->
    singleResultBoolean super(id, doLogQuery)

module.exports =
  Crud:Crud
  crud: factory Crud
  ThenableCrud: ThenableCrud
  thenableCrud: factory ThenableCrud
  HasManyCrud: HasManyCrud
  hasManyCrud: factory HasManyCrud
