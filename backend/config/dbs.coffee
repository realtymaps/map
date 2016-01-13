knex = require 'knex'
pg = require 'pg'
Promise = require 'bluebird'
config = require './config'
logger = require './logger'
do require '../../common/config/dbChecker.coffee'
_ = require 'lodash'


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


_shutdown = (db, name) ->
  if name == 'pg'
    _barePgShutdown()
  else
    _knexShutdown(db, name)


shutdown = () ->
  logger.info 'database shutdowns initiated ...'

  return Promise.join Promise.all _.map(connectedDbs, _shutdown), () ->
    logger.info 'all databases successfully shut down.'
  .catch (error) ->
    logger.error 'all databases shut down (?), some with errors.'
    Promise.reject(error)


getKnex = (dbName) ->
  if !connectedDbs[dbName]?
    connectedDbs[dbName] = knex(config.DBS[dbName.toUpperCase()])
  connectedDbs[dbName]


getPlainClient = (dbName, handler) ->
  dbConfig = config.DBS[dbName.toUpperCase()]
  client = new pg.Client(dbConfig.connection)
  promiseQuery = Promise.promisify(client.query, client)
  streamQuery = client.query.bind(client)
  Promise.promisify(client.connect, client)()
  .then () ->
    handler(((sql, args...) -> promiseQuery(sql.toString(), args...)), streamQuery)
  .finally () ->
    try
      client.end()
    catch err
      logger.warn "Error disconnecting raw db connection: #{err}"

transaction = (dbName, queryCb, postCatchCb) ->
  getKnex(dbName).transaction (trx) ->
    queryCb(trx)
    .then trx.commit
    .catch () ->
      trx.rollback()
      logger.debug 'transaction reverted'
      postCatchCb() if postCatchCb?


module.exports =
  shutdown: shutdown
  get: getKnex
  getPlainClient: getPlainClient
  transaction: transaction
