knex = require 'knex'
pg = require 'pg'
Promise = require 'bluebird'
config = require './config'
logger = require('./logger').spawn('dbs')
do require '../../common/config/dbChecker.coffee'
_ = require 'lodash'


connectedDbs =
  pg: pg


enabled = true
disableMessage = null
knexInUse = false
plainClientCount = 0

_knexShutdown = (db, name) ->
  logger.debug "... attempting '#{name}' database shutdown ..."
  db.destroy()
  .then () ->
    logger.debug "... '#{name}' database shutdown complete ..."
  .catch (error) ->
    logger.error "!!! '#{name}' database shutdown error: #{error}"
    Promise.reject(error)


_barePgShutdown = () ->
  new Promise (resolve, reject) ->
    logger.debug "... attempting bare pg database shutdown ..."
    pg.on 'end', () ->
      logger.debug "... bare pg database shutdown complete ..."
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
  if !enabled
    return knex(client: 'pg')
  knexInUse = true
  if !connectedDbs[dbName]?
    connectedDbs[dbName] = knex(config.DBS[dbName.toUpperCase()])
  connectedDbs[dbName]


getPlainClient = (dbName, handler) ->
  if !enabled
    throw new Error("database is disabled (#{disableMessage}), can't get plain db client")
  dbConfig = config.DBS[dbName.toUpperCase()]
  client = new pg.Client(dbConfig.connection)
  promiseQuery = Promise.promisify(client.query, client)
  streamQuery = client.query.bind(client)
  plainClientCount++
  Promise.promisify(client.connect, client)()
  .then () ->
    handler(((sql, args...) -> promiseQuery(sql.toString(), args...)), streamQuery)
  .finally () ->
    plainClientCount--
    try
      client.end()
    catch err
      logger.warn "Error disconnecting raw db connection: #{err}"

transaction = (dbName, queryCb, postCatchCb) ->
  getKnex(dbName).transaction (trx) ->
    queryCb(trx)
    .catch (err) ->
      logger.debug "transaction reverted: #{err}"
      postCatchCb(err) if postCatchCb?
      throw err

enable = () ->
  enabled = true

disable = (message) ->
  if knexInUse || plainClientCount
    inUse = Object.keys(_.omit(connectedDbs, 'pg'))
    if plainClientCount > 0
      inUse.push("plain:#{plainClientCount}")
    throw new Error("Can't disable database; some database clients already in use: (#{inUse.join(', ')})")
  enabled = false
  disableMessage = message


module.exports =
  shutdown: shutdown
  get: getKnex
  getPlainClient: getPlainClient
  transaction: transaction
  isDisabled: () -> if !enabled then disableMessage else false
  enable: enable
  disable: disable
