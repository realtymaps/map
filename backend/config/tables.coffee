dbs = require '../config/dbs'

_buildQueries = (tables) ->
  queries = {}
  for id, tableSpecifier of tables
    do (id, tableSpecifier) ->
      [dbName, tableName] = tableSpecifier.split('.')
      query = (transaction=dbs[dbName].knex) -> transaction(tableName)
      query.tableName = tableName
      queries[id] = query
  queries


module.exports =
  config:
    dataNormalization: 'users.data_normalization_config'
    group: 'users.auth_group'
    permission: 'users.auth_permission'
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
  userData:
    session: 'users.session'
    sessionSecurity: 'users.session_security'
    user: 'users.auth_user'
    userState: 'users.user_state'
    
# set up this way so IntelliJ's autocomplete works
for key,val of module.exports
  module.exports[key] = _buildQueries(val)
