config = require '../config/config'
module.exports =
  config:
    dataNormalization: 'config_data_normalization'
    mls: 'config_mls'
    keystore: 'config_keystore'
    externalAccounts: 'config_external_accounts'
    notification: 'config_notification'
    dataSourceFields: 'config_data_source_fields'
    dataSourceLookups: 'config_data_source_lookups'
  lookup:
    usStates: 'lookup_us_states'
    accountUseTypes: 'lookup_account_use_types'
    fipsCodes: 'lookup_fips_codes'
    mlsFipsCodes: 'lookup_mls_fips_code'
  property:
    listing: 'data_normal_listing'
    tax: 'data_normal_tax'
    deed: 'data_normal_deed'
    mortgage: 'data_normal_mortgage'
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
    subtaskErrorHistory: 'jq_subtask_error_history'
    currentSubtasks: 'jq_current_subtasks'
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
    m2m_user_locations: 'auth_m2m_user_locations'
    m2m_user_mls: 'auth_m2m_user_mls'
    toM_errors: 'auth_2m_errors'
  user:
    profile: 'user_profile'
    project: 'user_project'
    company: 'user_company'
    accountImages: 'user_account_images'
    notes: 'user_notes'
    drawnShapes: 'user_drawn_shapes'
    creditCards: 'user_credit_cards'
  mail:
    campaign: 'user_mail_campaigns'
    letters: 'user_mail_letters'
