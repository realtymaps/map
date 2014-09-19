# Promise = require "bluebird"
db = require('../config/dbs').properties
safeQuery = require './bookshelfext/bookshelf.raw'
all =  require('./sql/sql.properties.mls').all

module.exports =
  getAllMLS: (obj, next) ->
    sql = all(obj)
    safeQuery db, sql, next, 'getAllMLS'
