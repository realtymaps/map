knex = require 'knex'
pg = require 'pg'
Promise = require 'bluebird'
config = require './config'
logger = require('./logger').spawn('dbs')
_ = require 'lodash'
shutdown = require './shutdown'


if !config.DBS.MAIN.connection && !process.env.IS_HEROKU
  logger.error 'Database connection URL not available; did you use foreman?'
  process.exit(1)


connectedDbs = {}
connectionless = knex(client: 'pg')
_enabled = true


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


shutdown = (opts={}) ->
  {quiet} = opts
  if quiet
    log = logger.debug.bind(logger)
  else
    log = logger.info.bind(logger)

  log 'database shutdowns initiated ...'

  return Promise.join _barePgShutdown, Promise.all(_.map(connectedDbs, _knexShutdown)), () ->
    log 'all databases successfully shut down.'
    connectedDbs = {}
    delete require.cache[require.resolve('pg')]
    pg = require 'pg'
  .catch (error) ->
    logger.error 'all databases shut down (?), some with errors.'
    Promise.reject(error)


get = (dbName) ->
  if !_enabled
    return connectionless
  if dbName == 'pg'
    return pg
  if !connectedDbs[dbName]?
    connectedDbs[dbName] = knex(config.DBS[dbName.toUpperCase()])
  connectedDbs[dbName]


getPlainClient = (dbName, handler) ->
  if !_enabled
    throw new Error("database is disabled, can't get plain db client")
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


transaction = (args...) ->
  # allow the 'main' arg to be omitted
  if typeof(args[0]) != 'string'
    args.unshift('main')
  [dbName, queryCb, errCb] = args
  get(dbName).transaction (trx) ->
    queryCb(trx)
    .catch (err) ->
      logger.debug "transaction reverted: #{err}"
      errCb?(err)
      throw err


module.exports =
  shutdown: shutdown
  get: get
  getPlainClient: getPlainClient
  transaction: transaction
  connectionless: connectionless
  isEnabled: () -> _enabled
  enable: () -> _enabled = true
  disable: () -> _enabled = false
