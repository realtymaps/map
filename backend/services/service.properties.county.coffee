db = require('../config/dbs').properties
logger =  require '../config/logger'
fakeLogger =
  info: ->
    logger.info
  log: ->
  error: (msg)->
    logger.error(msg)

safeQuery = require('bookshelf.raw.safe')(fakeLogger).safeQuery
countySql = require('./sql/sql.properties.county')
status =  require '../../common/utils/httpStatus'

debug =( (fnName = "", sql) ->
  logger.debug "#{fnName} : calling with #{sql}" if sql?)

###
@author Nick McCready
Object in all cases has a getSomething database query, which uses the @parm queryOpts param
to build the correct sql.

After that the query is called via safeQuery @return a promise in all cases.
###

# ORIGINAL QUERY - WORKS -- SWAPPED OUT WITH RAW QUERY
#        var CountyData = bookshelf.Collection.extend({
#            tableName: 'county_data1_copy'
#        });
#        var test = new CountyData();
#        console.log(obj);
#        var tquery = buildQuery(obj);
#        console.log ("returned tquery = " + tquery);
#        test.query(tquery).fetch('acres').then(function(test) {callback(test.toJSON())});

module.exports = (overrideDb, overrideSafeQuery,
overrideCountySql, overrideLogger) ->

  db = overrideDb if overrideDb
  safeQuery = overrideSafeQuery if overrideSafeQuery
  countySql = overrideCountySql if overrideCountySql
  logger = overrideLogger if overrideLogger

  ###
  @param queryOpts
  ###
  getAll: (queryOpts, next) ->
    try
      sql = countySql.all queryOpts, next
    catch e
      switch e.name
        when 'SqlTypeError'
          next? status:status.BAD_REQUEST, message: e.message

    safeQuery db, sql, next, 'getAll'
