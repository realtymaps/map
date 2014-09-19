db = require('../config/dbs').properties
safeQuery = require './bookshelfext/bookshelf.raw'
countySql = require('./sql/sql.properties.county')

debug =( (fnName = "", sql) ->
  logger.debug "#{fnName} : calling with #{sql}" if sql?)

logger =  require '../config/logger'
###
@author Nick McCready
Object in all cases has a getSomething database query, which uses the @parm queryOpts param
to build the correct sql.

After that the query is called via safeQuery @return a promise in all cases.
###
module.exports = (overrideDb, overrideSafeQuery,
overrideCountySql, overrideDebug, overrideLogger) ->

  db = overrideDb if overrideDb
  safeQuery = overrideSafeQuery if overrideSafeQuery
  countySql = overrideCountySql if overrideCountySql
  debug = overrideDebug if overrideDebug
  logger = overrideLogger if overrideLogger

  ###
  @param queryOpts
  ###
  getAll: (queryOpts, next) ->
    # ORIGINAL QUERY - WORKS -- SWAPPED OUT WITH RAW QUERY
    #        var CountyData = bookshelf.Collection.extend({
    #            tableName: 'county_data1_copy'
    #        });
    #        var test = new CountyData();
    #        console.log(obj);
    #        var tquery = buildQuery(obj);
    #        console.log ("returned tquery = " + tquery);
    #        test.query(tquery).fetch('acres').then(function(test) {callback(test.toJSON())});
    sql = countySql.all queryOpts, next
    safeQuery db, sql, next, 'getAll'

  getAddresses: (queryOpts, next) ->
    sql = countySql.allByAddressNumbers queryOpts
    safeQuery db, sql, next, 'getAddresses'

  getByApn: (queryOpts, next) ->
    sql = countySql.allByApn queryOpts
    safeQuery db, sql, next, 'getByApn'
