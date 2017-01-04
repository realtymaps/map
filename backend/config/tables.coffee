dbs = require '../config/dbs'
config = require '../config/config'
_ = require 'lodash'


# setting on module.exports before processing to help with IDE autocomplete
module.exports =
  config:
    dataNormalization: 'config_data_normalization'
    mls: 'config_mls'
    keystore: 'config_keystore'
    externalAccounts: 'config_external_accounts'
    dataSourceFields: 'config_data_source_fields'
    dataSourceLookups: 'config_data_source_lookups'
    dataSourceDatabases: 'config_data_source_databases'
    dataSourceObjects: 'config_data_source_objects'
    dataSourceTables: 'config_data_source_tables'
    handlersEventMap: 'config_handlers_event_map'
    pva: 'config_pva'
  lookup:
    accountUseTypes: 'lookup_account_use_types'
    fipsCodes: 'lookup_fips_codes'
    mls: 'lookup_mls'
    mls_m2m_fips_code_county: 'lookup_mls_m2m_fips_code_county'
  normalized:
    listing: 'normalized.listing'
    tax: 'normalized.tax'
    deed: 'normalized.deed'
    mortgage: 'normalized.mortgage'
    parcel: 'normalized.parcel'
    agent: 'normalized.agent'
    fipscodeLocality: 'normalized.fipscode_locality'
  finalized:
    combined: 'data_combined'
    parcel: 'data_parcel'
    photo: 'data_photo'
    agent: 'data_agent'
  deletes:
    photos: 'deletes_photos'
    combined: 'deletes_combined'
    parcel: 'deletes_parcel'
    retry_photos: 'retry_photos'  # this isn't a delete table, but is a similar idea, and didn't have its own category
  jobQueue:
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
  user:
    profile: 'user_profile'
    project: 'user_project'
    company: 'user_company'
    blobs: 'user_blobs'
    notes: 'user_notes'
    drawnShapes: 'user_drawn_shapes'
    creditCards: 'user_credit_cards'
    errors: 'user_errors'
    notificationQueue: 'user_notification_queue'
    notificationExpired: 'user_notification_expired'
    notificationConfig: 'user_notification_config'
    eventsQueue: 'user_events_queue'
  mail:
    campaign: 'user_mail_campaigns'
    letters: 'user_mail_letters'
    pdfUpload: 'user_pdf_uploads'
  temp: 'raw_temp.'
  history:
    event: 'history_event'
    dataLoad: 'history_data_load'
    user: 'history_user'
    shell: 'history_shell'
    requestError: 'history_request_error'
  cartodb:
    syncQueue: 'cartodb_sync_queue'


_setup = (baseObject) ->
  for key, value of baseObject
    if typeof(value) == 'object'
      _setup(value)
      continue
    parts = value.split('.')
    if parts.length > 1
      dbName = parts[0]
      tableName = parts[1]
    else
      dbName = 'main'
      tableName = value
    baseObject[key] = do (dbName, tableName) ->
      ###
      subid explanation:
      - some cases there are many table to serve the load of one domain
      - example: there's not just 1 `tax` table, there's a lot of `tax_<fips>` tables
      - subid allows having a collection of tables all serving 1 purpose (and with 1 entry in `tables`)
      - major performance improvement to do that
      ###
      buildTableName = dbs.buildTableName(tableName)
      db = dbs.get(dbName)
      query = (opts={}) ->
        client = opts.transaction ? db
        if opts.subid
          fullTableName = buildTableName(opts.subid)
        else
          fullTableName = tableName
        if opts.as
          ret = client.from(db.raw("#{fullTableName} AS #{opts.as}"))
        else
          ret = client.from(fullTableName)
        ret.raw = db.raw.bind(db)
        ret.tableName = fullTableName
        ret.dbName = dbName
        ret
      transaction = (opts, handler) ->
        if handler == undefined
          # syntactic sugar to allow opts to be left out, but the handler to always be the last param
          handler = opts
          opts = undefined
        dbs.transaction dbName, (trx) ->
          fullOpts = _.extend({}, opts, {transaction: trx})
          handler(query(fullOpts), trx)
      query.tableName = tableName
      query.buildTableName = buildTableName
      query.dbName = dbName
      query.transaction = transaction
      query.raw = db.raw.bind(db)
      query

_setup(module.exports)
