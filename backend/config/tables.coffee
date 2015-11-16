logger = require '../config/logger'
dbs = require '../config/dbs'
clone = require 'clone'


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


_buildQueries = (tables) ->
  queries = {}
  for id, bootstrapper of tables
    queries[id] = _buildQuery(dbs.get('main'), bootstrapper.tableName)
  queries

mainBootstrapped = false

_bootstrapMain = () ->
  if mainBootstrapped
    return
  # then rewrite this module for its actual function instead of these bootstrappers
  for key,val of module.exports
    if key == 'buildRawTableQuery'
      continue
    module.exports[key] = _buildQueries(val)
  mainBootstrapped = true

_buildQueryBootstrapper = (groupName, id, tableName) ->
  # we need the bootstrapper to act and look the same as the query builder would -- so it will connect to the db,
  # rewrite itself out of the module, and then pass through to do whatever is expected
  bootstrapper = (args...) ->
    _bootstrapMain()
    return module.exports[groupName][id](args...)
  bootstrapper.tableName = tableName
  bootstrapper

#tried _.cloneDeep, and _extend {}, tableNames.. node-clone does as well as JSON.parse
module.exports = clone require './tableNames'

# set up this way so IntelliJ's autocomplete works

for groupName, groupConfig of module.exports
  #module.exports[groupName] = _buildQueries(groupConfig)
  module.exports[groupName] = {}
  for id, tableName of groupConfig
    module.exports[groupName][id] = _buildQueryBootstrapper(groupName, id, tableName)


module.exports.buildRawTableQuery = (tableName, args...) ->
  _buildQuery(dbs.get('raw_temp'), tableName)(args...)
