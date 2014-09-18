logger = require '../../config/logger'

makeStringLoggable = (name) ->
  return unless name
  name = name + ": "
  name

module.exports = (db, sql, callingFnName = 'bookshelf.raw') ->
  throw new Error 'db is not defined' unless db
  throw new Error 'sql is not defined' unless sql
  makeStringLoggable callingFnName

  logger.debug callingFnName + "'#{sql}'"

  db.knex.raw(sql)
  .then (data) ->
    return data.rows.toJSON
  .catch (e) ->
    logger "failed to #{callingFnName}#{e}"
    next(e)
