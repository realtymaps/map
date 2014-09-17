# Promise = require "bluebird"
dbs = require('../config/dbs').properties
safeQuery = require './bookshelfext/bookshelf.raw'
propertyQueries =  require('./sql/sql.properties.county')

module.exports = dbs.properties.Model.extend
  getAll: (obj, callback) ->
    # ORIGINAL QUERY - WORKS -- SWAPPED OUT WITH RAW QUERY
    #        var CountyData = bookshelf.Collection.extend({
    #            tableName: 'county_data1_copy'
    #        });
    #        var test = new CountyData();
    #        console.log(obj);
    #        var tquery = buildQuery(obj);
    #        console.log ("returned tquery = " + tquery);
    #        test.query(tquery).fetch('acres').then(function(test) {callback(test.toJSON())});
    sql = propertyQueries.all(obj)
    safeQuery db, sql, 'getAll'

  getAddresses: (obj, callback) ->
    sql = propertyQueries.allByAddressNumbers(obj)
    safeQuery db, sql, 'getAddresses'

  getByApn: (obj, callback) ->
    sql = propertyQueries.allByApn(obj)
    safeQuery db, sql, 'getByApn'
