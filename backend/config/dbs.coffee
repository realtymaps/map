knex = require 'knex'
bookshelf = require 'bookshelf'
pg = require 'pg'
Promise = require 'bluebird'

config = require './config'
logger = require './logger'
do require '../../common/config/dbChecker.coffee'

bookshelfRaw = require('bookshelf.raw.safe')(logger)

# bind the bookshelf raw safe query logic into the db object
properties = bookshelf knex(config.PROPERTY_DB)
properties.raw = bookshelfRaw.safeQuery.bind(bookshelfRaw, properties)


shutdown = () ->
  logger.info 'database shutdowns initiated...'

  pgDbShutdown = new Promise (resolve, reject) ->
    pg.on 'end', () ->
      logger.info "... 'pg' database shutdown complete ..."
      process.nextTick resolve
    pg.on 'error', (error) ->
      logger.error "!!! 'pg' database shutdown error: #{error}"
      process.nextTick reject.bind(null, error)
    pg.end()

  propertyDbShutdown = module.exports.properties.knex.destroy()
  .then () ->
    logger.info "... 'properties' database shutdown complete ..."
  .catch (error) ->
    logger.error "!!! 'properties' database shutdown error: #{error}"
    Promise.reject(error)

  return Promise.join pgDbShutdown, propertyDbShutdown, (pgDbShutdown, propertyDbShutdown) ->
    logger.info 'all databases successfully shut down.'
  .catch (error) ->
    logger.error 'all databases shut down, some with errors.'
    Promise.reject(error)


module.exports =
  users: properties
  properties: properties
  pg: pg
  shutdown: shutdown
