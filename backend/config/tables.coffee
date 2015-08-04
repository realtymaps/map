dbs = require '../config/dbs'

_buildQueries = (tables) ->
  queries = {}
  for id, tableSpecifier of tables
    do (id, tableSpecifier) ->
      [dbName, tableName] = tableSpecifier.split('.')
      query = (transaction=dbs[dbName].knex) ->
        ret = transaction.from(tableName)
        ret.raw = transaction.raw
        ret
      query.tableName = tableName
      queries[id] = query
  queries


module.exports =
  config:
    dataNormalization: 'users.data_normalization_config'
    mls: 'users.mls_config'
  propertyData:
    mls: 'properties.mls_data'
    rootParcel: 'properties.parcels'
    parcel: 'properties.mv_parcels'
    propertyDetails: 'properties.mv_property_details'
    combined: 'properties.combined_data'
  jobQueue:
    dataLoadHistory: 'properties.data_load_history'
    taskConfig: 'users.jq_task_config'
    subtaskConfig: 'users.jq_subtask_config'
    queueConfig: 'users.jq_queue_config'
    taskHistory: 'users.jq_task_history'
    currentSubtasks: 'users.jq_current_subtasks'
    subtaskErrorHistory: 'users.jq_subtask_error_history'
    jqSummary: 'users.jq_summary'
    dataHealth: 'properties.data_health'
  userData:
    session: 'users.session'
    sessionSecurity: 'users.session_security'
    user: 'users.auth_user'
    auth_group: 'users.auth_group'
    auth_user_groups: 'users.auth_user_groups'
    #consider renaming in the database to auth_user_permissions to be consistent
    auth_user_user_permissions: 'users.auth_user_user_permissions'
    auth_permission: 'users.auth_permission'
    auth_group_permissions: 'users.auth_group_permissions'

    auth_user_profile: 'users.auth_user_profile'
    project: 'users.project'

    externalAccounts: 'users.external_accounts'
    us_states: 'users.us_states'
    company: 'users.company'
    account_images: 'users.account_images'
    account_use_types:'users.account_use_types'

# set up this way so IntelliJ's autocomplete works
for key,val of module.exports
  module.exports[key] = _buildQueries(val)
