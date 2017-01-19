_ = require 'lodash'
logger = require('../../config/logger').spawn('crud:serviceHelpers')
{PartiallyHandledError, isUnhandled} = require '../errors/util.error.partiallyHandledError'
{singleRow, buildQuery} = require '../util.sql.helpers'
factory = require '../util.factory'
BaseObject = require '../../../common/utils/util.baseObject'
{IsIdObjError} = require '../errors/util.errors.crud.coffee'
clone = require 'clone'

logQuery = (q, doLogQuery) ->
  logger.debug(q.toString()) if doLogQuery

execQ = (q, doLogQuery) ->
  # console.trace()
  logQuery q, doLogQuery
  q

withSafeEntity = (entity, safe, cb, skipSafeError) ->
  if entity? and !safe
    throw new Error('safe must be defined if entity is defined') unless skipSafeError
  if entity? and safe?.length
    throw new Error('safe must be Array type') unless _.isArray safe
    entity = _.pick(entity, safe)
  _.each entity, (value, key) ->
    if _.isArray(value)
      entity[key] = JSON.stringify(value)
  cb(entity or {}, safe)

class Crud extends BaseObject
  constructor: (@dbFn, @idKey = 'id') ->
    super()
    unless _.isFunction @dbFn
      logger.debug @dbFn
      throw new Error('dbFn must be a knex function')

  # a function to clone a instance so that, init in Thennable Trait can be called
  # with different restrictions to make CrudServices adhoc
  # IDEA: say we have service.user , which is wrapped, to have an unwrapped version
  # service.user.clone().init(false,false,false)
  clone: () ->
    new Crud @dbFn, @idKey

  idObj: (val) ->
    val = clone val
    if _.isNumber(val) or _.isString(val)
      obj = {}
      obj[@idKey] = val
      return obj
    if !_.isObject(val) or _.isArray(val)
      throw new IsIdObjError("val: #{val} typeof #{typeof(val)} must be an object, or Number but not an Array!")
    return val

  count: (query = {}, doLogQuery = false, fnExec = execQ) ->
    fnExec @dbFn().where(query).count('*'), doLogQuery or @doLogQuery

  getAll: () ->
    @_getAll 'dbFn', arguments...

  _getAll: (dbFn, query = {}, doLogQuery = false, fnExec = execQ) ->
    where = buildQuery(knex: @[dbFn](), entity: query)
    fnExec where, doLogQuery or @doLogQuery

  getById: () ->
    @_getById 'dbFn', arguments...

  _getById: (dbFn, id, doLogQuery = false, entity, safe, fnExec = execQ) ->
    if !id?
      throw new Error("#{@dbFn.tableName}: id is required")
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @[dbFn]().where(_.extend @idObj(id), entity), doLogQuery or @doLogQuery

  update: (id, entity, safe, doLogQuery = false, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @dbFn().where(@idObj(id)).returning(@idKey).update(entity), doLogQuery or @doLogQuery
    , true

  create: (entity, id, doLogQuery = false, safe, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      # support entity or array of entities
      if _.isArray entity
        fnExec @dbFn().returning(@idKey).insert(entity), doLogQuery or @doLogQuery
      else
        obj = {}
        obj = @idObj id if id?
        # logger.debug.cyan id, true
        newEntity = _.extend {}, entity, obj
        # logger.debug.yellow newEntity,true
        fnExec @dbFn().returning(@idKey).insert(newEntity), doLogQuery or @doLogQuery
    , true

  upsert: (entity, unique, doUpdate = true, safe, doLogQuery = false, fnExec = execQ) ->
    query = _.pick entity, unique
    throw new Error('unique field(s) must be provided') unless !_.isEmpty query

    @getAll query, doLogQuery, fnExec
    .then (found) =>
      throw new Error('must match exactly one or zero records') unless found.length <= 1

      if found.length == 0
        Crud::create.call @, entity, entity[@idKey], doLogQuery or @doLogQuery, safe, fnExec
        .then (inserted) ->
          throw new Error('exactly one record should have been inserted') unless inserted.length == 1
          inserted

      else if found.length == 1
        return [ found[0][@idKey] ] unless doUpdate
        Crud::update.call @, found[0][@idKey], entity, safe, doLogQuery or @doLogQuery, fnExec
        .then (updated) ->
          throw new Error('exactly one record should have been updated') unless updated.length == 1
          updated

  delete: (id, doLogQuery = false, entity, safe, fnExec = execQ) ->
    withSafeEntity entity, safe, (entity, safe) =>
      fnExec @dbFn().where(_.extend @idObj(id), entity).delete(), doLogQuery or @doLogQuery
    , true

  base: () ->
    super([Crud,@].concat(_.toArray arguments)...)

class HasManyCrud extends Crud
  constructor: (dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, idKey) ->
    super(dbFn, idKey)
    @setIdStrs @origRootIdStr, @origJoinIdStr

  clone: () ->
    new HasManyCrud @dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, @idKey

  joinQuery: () ->
    @joinCrud.dbFn()
    .select(@rootCols...)
    .innerJoin(@dbFn.tableName, @rootIdStr, @joinIdStr)

  setIdStrs: (rootIdStr,joinIdStr) ->
    @rootIdStr = rootIdStr or @dbFn.tableName + '.id'
    @joinIdStr = joinIdStr or @joinCrud.dbFn.tableName + ".#{@dbFn.tableName}_id"
    # logger.debug 'setIdStrs !!!!!!!!!!!!!!!!!!'
    # logger.debug @rootIdStr
    # logger.debug @joinIdStr

  count: (query = {}, doLogQuery = false, fnExec = execQ) ->
    fnExec @joinQuery().where(query).count('*'), doLogQuery

  getAll: () ->
    @_getAll 'joinQuery', arguments...

  getById: () ->
    @_getById 'joinQuery', arguments...

  create: () ->
    @joinCrud.create(arguments...)

  upsert: () ->
    @joinCrud.upsert(arguments...)

  update: () ->
    @joinCrud.update(arguments...)

  delete: () ->
    @joinCrud.delete(arguments...)

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
    # logger.debug.yellow result
    # logger.debug.yellow result.rowCount
    unless doRowCount
      return result == 1
    result.rowCount == 1
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error)

thenables = [Crud, HasManyCrud].map (baseKlass) ->
  class ThenableTrait extends baseKlass
    constructor: (args...) ->
      @conArgs = args #save off original args so it can be cloned with no args via clone
      super(args...)
      # console.log 'ThenableTrait: init()'
      @init()

    clone: () ->
      new @constructor(@conArgs...)#this ensures the derived classes are called correctly

    init:(@doWrapGetAllThen = true, @doWrapGetThen = true, @doWrapSingleThen = true) => #TODO: should @doWrapSingleThen default to 'singleRaw'?
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
      q.then singleRow

    #here down return thenables to be consistent on service returns for single items
    update: () ->
      q = super(arguments...)
      return q unless @doWrapSingleThen
      singleResultBoolean q

    create: () ->
      q = super(arguments...)
      logger.debug "@doWrapSingleThen: " + @doWrapSingleThen
      return q unless @doWrapSingleThen
      return q.then singleRow if @doWrapSingleThen == 'singleRaw'
      singleResultBoolean q, true

    upsert: () ->
      q = super(arguments...)
      return q unless @doWrapSingleThen
      return q.then singleRow if @doWrapSingleThen == 'singleRaw'
      singleResultBoolean q, true

    delete: () ->
      q = super(arguments...)
      return q unless @doWrapSingleThen
      return q.then singleRow if @doWrapSingleThen == 'singleRaw'
      singleResultBoolean q

  return ThenableTrait

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
  dbFnCalls: [ 'count','getAll','getById','update','create','upsert','delete']
