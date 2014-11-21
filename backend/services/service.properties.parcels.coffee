db = require('../config/dbs').properties
logger = require '../config/logger'
fakeLogger =
  info: ->
    logger.info
  log: ->
  error: (msg)->
    logger.error(msg)

safeQuery = require('bookshelf.raw.safe')(fakeLogger).safeQuery
sqlGen = require('./sql/sql.properties.parcels')
status = require '../../common/utils/httpStatus'

debug = (fnName = "", sql) ->
  logger.debug "#{fnName} : calling with #{sql}" if sql?

module.exports = (overrideDb, overrideSafeQuery, overrideSqlGen, overrideLogger) ->

  db = overrideDb if overrideDb
  safeQuery = overrideSafeQuery if overrideSafeQuery
  sqlGen = overrideSqlGen if overrideSqlGen
  logger = overrideLogger if overrideLogger

  getAll: (queryOpts, next) ->
    sql = sqlGen.all queryOpts, next
    safeQuery db, sql, next, 'getAll'

  getAllPolys: (queryOpts, next) ->
    sql = sql = sqlGen.allPolys queryOpts, next
    safeQuery db, sql, next, 'getAllPolys'
