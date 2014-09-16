knex = require 'knex'
bookshelf = require 'bookshelf'
pg = require 'pg'
Promise = require 'bluebird'

config = require './config'
logger = require './logger'
require('../../common/config/dbChecker.coffee')()


module.exports =
  users: bookshelf knex(config.USER_DB)
  properties: bookshelf knex(config.PROPERTY_DB)
  pg: pg

module.exports.shutdown = () ->
  logger.info "database shutdowns initiated..."

  pgDbShutdown = new Promise (resolve, reject) ->
    pg.on "end", () ->
      logger.info "... 'pg' database shutdown complete ..."
      process.nextTick resolve
    pg.on "error", (error) ->
      logger.error "!!! 'pg' database shutdown error: #{error}"
      process.nextTick reject.bind(null, error)
    pg.end()

  userDbShutdown = module.exports.users.knex.destroy()
  userDbShutdown.catch (error) ->
    logger.error "!!! 'users' database shutdown error: #{error}"
  userDbShutdown = userDbShutdown.then () ->
    logger.info "... 'users' database shutdown complete ..."

  propertyDbShutdown = module.exports.properties.knex.destroy()
  propertyDbShutdown.catch (error) ->
    logger.error "!!! 'properties' database shutdown error: #{error}"
  propertyDbShutdown = propertyDbShutdown.then () ->
    logger.info "... 'properties' database shutdown complete ..."

  allShutdown = Promise.join pgDbShutdown, userDbShutdown, propertyDbShutdown, (pgDbShutdown, userDbShutdown, propertyDbShutdown) ->
    logger.info "all databases successfully shut down."
  allShutdown.catch (error) ->
    logger.error "all databases shut down, some with errors."
  return allShutdown
