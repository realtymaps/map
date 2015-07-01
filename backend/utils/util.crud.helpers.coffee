logger = require '../config/logger'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
{singleRow} = require './util.sql.helpers'
_ = require 'lodash'

logQuery = (q, doLogQuery) ->
  logger.debug(q.toString()) if doLogQuery

execQ = (q, doLogQuery) ->
  logQuery q, doLogQuery
  q

class Crud
  constructor: (@dbFn) ->
    unless _.isFunction @dbFn
      throw 'dbFn must be a knex function'

  getAll: (doLogQuery = false) ->
    execQ @dbFn(), doLogQuery

  getById: (id, doLogQuery = false) ->
    execQ @dbFn().where(id: id), doLogQuery

  #here down return thenables to be consistent on service returns for single items
  update: (id, entity, safe = [], doLogQuery = false) ->
    execQ @dbFn.where(id: id).update _.pick(entity, safe), doLogQuery

  create: (entity, id, doLogQuery = false) ->
    execQ @dbFn.insert(entity), doLogQuery

  delete: (id, doLogQuery = false) ->
    execQ @dbFn.where(id: id).delete(), doLogQuery

  base: () ->
    super([Crud].concat(arguments)...)
###
NOTICE this really restricts how the crud is used!
Many times ThenableCrud should not even be instantiated until the
route layer where you know that you will definatley want a response totally in memory.
Many times returning the query itself is sufficent so it can be piped (MUCH better on memory)!
###
singleResultBoolean = (q) ->
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
  ThenableCrud: ThenableCrud
