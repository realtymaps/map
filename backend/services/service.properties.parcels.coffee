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

debug = ( (fnName = "", sql) ->
  logger.debug "#{fnName} : calling with #{sql}" if sql?)

module.exports = (overrideDb, overrideSafeQuery, overrideSqlGen, overrideLogger) ->

  db = overrideDb if overrideDb
  safeQuery = overrideSafeQuery if overrideSafeQuery
  sqlGen = overrideSqlGen if overrideSqlGen
  logger = overrideLogger if overrideLogger

  ###
  @param queryOpts
  ###
  getAll: (queryOpts, next) ->
    try
      sql = sqlGen.all queryOpts, next
    catch e
      switch e.name
        when 'SqlTypeError'
          next? status: status.BAD_REQUEST, message: e.message

    safeQuery db, sql, next, 'getAll'


  getAllPolys: (queryOpts, next) ->
    try
      sql = sqlGen.allPolys queryOpts, next
    catch e
      switch e.name
        when 'SqlTypeError'
          next? status: status.BAD_REQUEST, message: e.message

    safeQuery db, sql, next, 'getAllPolys'
