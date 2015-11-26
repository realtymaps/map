logger = require '../config/logger'
dbs = require '../config/dbs'
clone = require 'clone'
_ = require 'lodash'

escapeExports = ['bootstrapModule', 'buildRawTableQuery', 'dbFnFactory', 'dbFnsFactory']

_buildQuery = (db, tableName) ->
  query = (transaction=db, asName) ->
    if typeof(transaction) == 'string'
      # syntactic sugar to allow passing just the asName
      asName = transaction
      transaction = db
    if asName
      ret = transaction.from(db.raw("#{tableName} AS #{asName}"))
    else
      ret = transaction.from(tableName)
    ret.raw = db.raw.bind(db)
    ret
  query.tableName = tableName
  query


_buildQueries = (tables, db) ->
  throw new Error("_buildQueries: db is undefined") unless db
  queries = {}
  for id, bootstrapper of tables
    queries[id] = _buildQuery(db, bootstrapper.tableName)
  queries

mainBootstrapped = false

_bootstrapMain = (db) ->
  throw new Error("_bootstrapMain: db is undefined") unless db
  if mainBootstrapped
    return
  # then rewrite this module for its actual function instead of these bootstrappers
  for key,val of module.exports
    if _.contains escapeExports, key
      continue
    module.exports[key] = _buildQueries(val, db)
  mainBootstrapped = true

_buildQueryBootstrapper = (opts) ->
  {groupName, id, tableName, db} = opts
  db = db or dbs.get('main')
  throw new Error("_buildQueryBootstrapper: db is undefined") unless db
  # we need the bootstrapper to act and look the same as the query builder would -- so it will connect to the db,
  # rewrite itself out of the module, and then pass through to do whatever is expected
  bootstrapper = (args...) ->
    _bootstrapMain(db)
    return module.exports[groupName][id](args...)
  bootstrapper.tableName = tableName
  bootstrapper

#tried _.cloneDeep, and _extend {}, tableNames.. node-clone does as well as JSON.parse
module.exports = clone require './tableNames'

# set up this way so IntelliJ's autocomplete works

bootstrapModule = (db, doLog) ->
  mainBootstrapped = false
  for groupName, groupConfig of module.exports
    if _.contains escapeExports, groupName
      continue
    #module.exports[groupName] = _buildQueries(groupConfig)
    module.exports[groupName] = {}
    for id, tableName of groupConfig
      do (id, tableName) ->
        if doLog
          logger.debug {groupName, id}, true
        module.exports[groupName][id] = _buildQueryBootstrapper({groupName, id, tableName, db})
        return

bootstrapModule()

module.exports.bootstrapModule = bootstrapModule

module.exports.buildRawTableQuery = (tableName, args...) ->
  _buildQuery(dbs.get('raw_temp'), tableName)(args...)

module.exports.dbFnFactory = _buildQuery
module.exports.dbFnsFactory = (db, objTablesToDefined) ->
  for name, val of objTablesToDefined
    do(name, val) ->
      objTablesToDefined[name] = _buildQuery(db, name)
  objTablesToDefined
#allow the whole tables lib to be rebootstrapped if needed / say mocked
