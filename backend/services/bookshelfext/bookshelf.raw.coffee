logger = require '../../config/logger'
Promise = require 'bluebird'
status =  require '../../../common/utils/httpStatus'
errors = require '../sql/sql.errors'

logger.debug errors

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

handleError = (callingFnName, e, status, next) ->
  logger.error "failed to #{callingFnName}#{e.message}"

  next?({status:status, message: e.message})
  e.isLogged = true
  Promise.reject e

module.exports = (db, sql, next, callingFnName = 'bookshelf.raw') ->
  return Promise.reject 'db is not defined' unless db
  return Promise.reject 'sql is not defined' unless sql

  makeStringLoggable callingFnName

  #logger.sql callingFnName + "'#{sql}'"

  db.knex.raw(sql).then (data) ->
    logger.log "sql", "result: data.rows: %j", data.rows, {}
    if data.rows
      data.rows
    else
      []
  .catch (e) ->
    handleError callingFnName, e, status.NOT_FOUND, next
