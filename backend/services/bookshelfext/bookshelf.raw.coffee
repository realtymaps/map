logger = require '../../config/logger'
Promise = require 'bluebird'

makeStringLoggable = (name) ->
  return unless name
  name = name + ": "
  name

###
  Function to handle the basic rows convertion to JSON and handle basic error logging.
  In all error cases a Promise should be returned!

  @pram {object} db - database object, bookshelf
  @pram {string} sql - sql string to be sent to the db
  @pram {function} next - express error handler
  @pram {string} - callingFnName (optional) - string of calling function for logging
  @return {object} Promise
###
module.exports = (db, sql, next, callingFnName = 'bookshelf.raw') ->
  return Promise.reject('db is not defined') unless db
  return Promise.reject 'sql is not defined' unless sql

  makeStringLoggable callingFnName

  logger.debug callingFnName + "'#{sql}'"

  db.knex.raw(sql).then (data) ->
    data.rows.toJSON()
  .catch (e) ->
    logger.error "failed to #{callingFnName}#{e}"
    next?(e)
    Promise.reject e
