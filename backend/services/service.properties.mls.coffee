# Promise = require "bluebird"
db = require('../config/dbs').properties
safeQuery = require './bookshelfext/bookshelf.raw'
all =  require('./sql/sql.properties.mls').all

module.exports = dbs.properties.Model.extend
  getAllMLS: (obj) ->
    sql = all(obj)
    safeQuery db, sql, 'getAllMLS'
