# Promise = require "bluebird"
db = require('../config/dbs').properties
logger =  require '../config/logger'
safeQuery = (require('bookshelf.raw.safe')(logger)).safeQuery
all =  require('./sql/sql.properties.mls').all

module.exports =
  getAllMLS: (obj, next) ->
    sql = all(obj)
    safeQuery db, sql, next, 'getAllMLS'
