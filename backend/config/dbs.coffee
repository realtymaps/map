knex = require 'knex'
pg = require 'pg'
Promise = require 'bluebird'
config = require './config'
logger = require './logger'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
do require '../../common/config/dbChecker.coffee'


connectedDbs =
  pg: pg


_knexShutdown = (db, name) ->
  logger.info "... attempting '#{name}' database shutdown ..."
  db.destroy()
  .then () ->
    logger.info "... '#{name}' database shutdown complete ..."
  .catch (error) ->
    logger.error "!!! '#{name}' database shutdown error: #{error}"
    Promise.reject(error)

    
_barePgShutdown = () ->
  new Promise (resolve, reject) ->
    logger.info "... attempting bare pg database shutdown ..."
    pg.on 'end', () ->
      logger.info "... bare pg database shutdown complete ..."
      process.nextTick resolve
    pg.on 'error', (error) ->
      logger.error "!!! bare pg database shutdown error: #{error}"
      process.nextTick reject.bind(null, error)
    pg.end()


shutdown = () ->
  logger.info 'database shutdowns initiated ...'

  pgDbShutdown = _barePgShutdown()
  onDemandDbsShutdown = Promise.all _.map(connectedDbs, _knexShutdown)

  return Promise.join pgDbShutdown, onDemandDbsShutdown, () ->
    logger.info 'all databases successfully shut down.'
  .catch (error) ->
    logger.error 'all databases shut down (?), some with errors.'
    Promise.reject(error)

    
getKnex = (dbName) ->
  if !connectedDbs[dbName]?
    dbConfig = config.DBS[dbName.toUpperCase()]
    connectedDbs[dbName] = knex(dbConfig)
  connectedDbs[dbName]

  
getPlainClient = (dbName, handler) ->
  pg.defaults.poolSize = config.SUBTASKS_PER_PROCESS || 1
  pg.defaults.poolIdleTimeout = config.DBS.PLAIN.POOL_IDLE_TIMEOUT
  dbConfig = config.DBS[dbName.toUpperCase()]
  new Promise (resolve, reject) ->
    pg.connect dbConfig.connection, (err, client, done) ->
      if err
        done(client?)
        reject(new PartiallyHandledError(err, "Problem getting plain pg client for #{dbName} db"))
        return
      isDone = false
      isResolved = false
      Promise.try () ->
        handler(client)
      .then (result) ->
        isDone = true
        done()
        isResolved = true
        resolve(result)
      .catch (err) ->
        try
          if !isDone
            done(true)
          if !isResolved
            reject(err)
        catch err
          # noop
      

module.exports =
  shutdown: shutdown
  get: getKnex
  getPlainClient: getPlainClient
