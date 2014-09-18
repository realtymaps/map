logger = require '../../config/logger'
Promise = require 'bluebird'

makeStringLoggable = (name) ->
  return unless name
  name = name + ": "
  name

module.exports = (db, sql, next, callingFnName = 'bookshelf.raw') ->
  throw new Error 'db is not defined' unless db
  throw new Error 'sql is not defined' unless sql
  makeStringLoggable callingFnName

  logger.debug callingFnName + "'#{sql}'"


  db.knex.raw(sql).then (data) ->
    data.rows.toJSON()
  .catch (e) ->
    logger.error "failed to #{callingFnName}#{e}"
    next(e)
    Promise.reject e
