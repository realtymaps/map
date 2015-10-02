dbs = require '../config/dbs'
logger = require '../config/logger'


buildQuery = (dbName, tableName) ->
  query = (transaction=dbs[dbName].knex, asName) ->
    if typeof(transaction) == 'string'
      # syntactic sugar to allow passing just the asName
      asName = transaction
      transaction = dbs[dbName].knex
    if asName
      ret = transaction.from(dbs[dbName].knex.raw("#{tableName} AS #{asName}"))
    else
      ret = transaction.from(tableName)
    ret.raw = dbs[dbName].knex.raw.bind(transaction)
    ret
  query.tableName = tableName
  query.transaction = dbs[dbName].knex.transaction.bind(dbs[dbName].knex)
  query.raw = dbs[dbName].knex.raw.bind(dbs[dbName].knex)
  query
  
  
_buildQueries = (tables) ->
  queries = {}
  for id, tableName of tables
    queries[id] = buildQuery('properties', tableName)
  queries


module.exports =
  config:
    dataNormalization: 'data_normalization_config'
    mls: 'mls_config'
    keystore: 'keystore'
    dataSource: 'data_source_fields'
    dataSourceLookups: 'data_source_lookups'
  propertyData:
    listing: 'normal_listing_data'
    tax: 'normal_tax_data'
    deed: 'normal_deed_data'
    rootParcel: 'parcels'
    parcel: 'mv_parcels'
    propertyDetails: 'mv_property_details'
    combined: 'combined_data'
    deletes: 'combined_data_deletes'
  jobQueue:
    dataLoadHistory: 'data_load_history'
    taskConfig: 'jq_task_config'
    subtaskConfig: 'jq_subtask_config'
    queueConfig: 'jq_queue_config'
    taskHistory: 'jq_task_history'
    currentSubtasks: 'jq_current_subtasks'
    subtaskErrorHistory: 'jq_subtask_error_history'
    jqSummary: 'jq_summary'
    dataHealth: 'data_health'
  userData:
    session: 'session'
    sessionSecurity: 'session_security'
    user: 'auth_user'
    auth_group: 'auth_group'
    auth_user_groups: 'auth_user_groups'
    #consider renaming in the database to auth_user_permissions to be consistent
    auth_user_user_permissions: 'auth_user_user_permissions'
    auth_permission: 'auth_permission'
    auth_group_permissions: 'auth_group_permissions'

    auth_user_profile: 'auth_user_profile'
    project: 'project'

    externalAccounts: 'external_accounts'
    us_states: 'us_states'
    company: 'company'
    account_images: 'account_images'
    account_use_types:'account_use_types'
    notes: 'notes'

# set up this way so IntelliJ's autocomplete works
for key,val of module.exports
  module.exports[key] = _buildQueries(val)

module.exports.buildQuery = buildQuery
