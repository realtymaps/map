logger = require '../config/logger'
config = require '../config/config'
dbs = require '../config/dbs'


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



module.exports =
  config:
    dataNormalization: 'config_data_normalization'
    mls: 'config_mls'
    keystore: 'config_keystore'
    externalAccounts: 'config_external_accounts'
    notification: 'config_notification'
  lookup:
    usStates: 'lookup_us_states'
    accountUseTypes: 'lookup_account_use_types'
    fipsCodes: 'lookup_fips_codes'
  property:
    listing: 'data_normal_listing'
    tax: 'data_normal_tax'
    deed: 'data_normal_deed'
    combined: 'data_combined'
    deletes: 'data_combined_deletes'
    # the following are deprecated, so I'm not bothering to standardize their names
    rootParcel: 'parcels'
    parcel: 'mv_parcels'
    propertyDetails: 'mv_property_details'
  jobQueue:
    dataLoadHistory: 'jq_data_load_history'
    taskConfig: 'jq_task_config'
    subtaskConfig: 'jq_subtask_config'
    queueConfig: 'jq_queue_config'
    taskHistory: 'jq_task_history'
    currentSubtasks: 'jq_current_subtasks'
    subtaskErrorHistory: 'jq_subtask_error_history'
    summary: 'jq_summary'
  auth:
    session: config.SESSION_STORE.tableName  #auth_session
    sessionSecurity: 'auth_session_security'
    user: 'auth_user'
    group: 'auth_group'
    permission: 'auth_permission'
    # the following use _ separators, but are theoretically still camelCased, e.g. auth_m2m_lasers_sharkHeads
    m2m_user_permission: 'auth_m2m_user_permissions'
    m2m_user_group: 'auth_m2m_user_groups'
    m2m_group_permission: 'auth_m2m_group_permissions'
  user:
    profile: 'user_profile'
    project: 'user_project'
    company: 'user_company'
    accountImages: 'user_account_images'

    
# set up this way so IntelliJ's autocomplete works

for groupName, groupConfig of module.exports
  #module.exports[groupName] = _buildQueries(groupConfig)
  module.exports[groupName] = {}
  for id, tableName of groupConfig
    module.exports[groupName][id] = _buildQueryBootstrapper(groupName, id, tableName)


module.exports.buildRawTableQuery = (tableName, args...) ->
  _buildQuery(dbs.get('raw_temp'), tableName)(args...)
