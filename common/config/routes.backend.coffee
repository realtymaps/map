###
Object list of the defined routes. It's purpose is to keep the
frontend and backend in sync
###

apiBase = '/api'
apiBaseMls = "#{apiBase}/mls"
apiBaseMlsConfig = "#{apiBase}/mls_config"
apiBaseDataRules = "#{apiBase}/rules"
apiBaseDataSource = "#{apiBase}/data_source"
apiBaseDataSourceLookups = "#{apiBase}/lookups"
apiBaseUsers = "#{apiBase}/users"
apiBaseUsersGroups = "#{apiBase}/usersGroups"
apiBaseGroups = "#{apiBase}/groups"
apiBaseGroupsPermissions = "#{apiBase}/groupsPermissions"
apiBasePermissions = "#{apiBase}/permissions"
apiBaseProjects = "#{apiBase}/projects"
apiBaseProjects2 = "#{apiBase}/projects2"
apiBaseProfiles = "#{apiBase}/profiles"
apiBaseSession = "#{apiBase}/session"
apiBaseJobs = "#{apiBase}/jobs"
apiBaseCompanies = "#{apiBase}/companies"
apiBaseUsStates = "#{apiBase}/usStates"
apiBaseAccountUseTypes = "#{apiBase}/accountUseTypes"
apiBaseAccountImages = "#{apiBase}/accountImages"
apiBaseNotes = "#{apiBaseSession}/notes"
apiBaseClients = "#{apiBaseSession}/clients"
apiBaseMailCampaigns = "#{apiBase}/mailCampaigns"
apiBaseProjectsSession2 = "#{apiBaseSession}/projects2"

module.exports =
  views:
    rmap: '/rmap.html'
    admin: '/admin.html'
    mocksResults: '/mocks/results.html'
  wildcard:
    admin: '/admin*'
    frontend: '/*'
    backend: "#{apiBase}/*"
  userSession:
    apiBase: apiBaseSession
    identity: "#{apiBaseSession}/identity"
    updateState: "#{apiBaseSession}/identity/state"
    login: "#{apiBaseSession}/login"
    logout: "#{apiBaseSession}/logout"
    currentProfile: "#{apiBaseSession}/currentProfile"
    profiles: "#{apiBaseSession}/profiles"
    newProject: "#{apiBaseSession}/newProject"
    image: "#{apiBaseSession}/image"
    companyImage: "#{apiBaseSession}/companyImage/:account_image_id"
    root: apiBaseSession
    companyRoot: "#{apiBaseSession}/company"
    updatePassword: "#{apiBaseSession}/password"
    emailIsUnique: "#{apiBaseSession}/emailIsUnique"
  notesSession:
    apiBase: apiBaseNotes
    root: apiBaseNotes
    byId: "#{apiBaseNotes}/:id"
  projectSession:
    root: "#{apiBaseSession}/projects"
    byId: "#{apiBaseSession}/projects/:id"
    clients: "#{apiBaseSession}/projects/:id/clients"
    clientsById: "#{apiBaseSession}/projects/:id/clients/:client_id"
  # projectSession2:
  #   apiBase: apiBaseProjectsSession2
  #   root: apiBaseProjectsSession2
  #   byId: "#{apiBaseProjectsSession2}/:id"
  #   # clients: "#{apiBaseProjectsSession2}/:id/clients"
  #   # clientsById: "#{apiBaseProjectsSession2}/:id/clients/:client_id"
  #   notes: "#{apiBaseProjectsSession2}/:id/notes"
  #   notesById: "#{apiBaseProjectsSession2}/:id/notes/:note_id"
  #   drawnShapes: "#{apiBaseProjectsSession2}/:id/drawnByShapes"
  #   drawnShapesById: "#{apiBaseProjectsSession2}/:id/drawnByShapes/:drawn_shap_id"
  user:
    apiBase: apiBaseUsers
    root: apiBaseUsers
    byId: "#{apiBaseUsers}/:id"
    permissions: "#{apiBaseUsers}/:id/permissions"
    permissionsById: "#{apiBaseUsers}/:id/permissions/:permission_id"
    groups: "#{apiBaseUsers}/:id/groups"
    groupsById: "#{apiBaseUsers}/:id/groups/:group_id"
    profiles: "#{apiBaseUsers}/:id/profiles"
    profilesById: "#{apiBaseUsers}/:id/profiles/:profile_id"
  user_user_groups:
    apiBase: apiBaseUsersGroups
    root: apiBaseUsersGroups
    byId: "#{apiBaseUsersGroups}/:id"
  user_groups:
    apiBase: apiBaseGroups
    root: apiBaseGroups
    byId: "#{apiBaseGroups}/:id"
  user_group_permissions:
    apiBase: apiBaseGroupsPermissions
    root: apiBaseGroupsPermissions
    byId: "#{apiBaseGroupsPermissions}/:id"
  user_permissions:
    apiBase: apiBasePermissions
    root: apiBasePermissions
    byId: "#{apiBasePermissions}/:id"
  user_projects:
    apiBase: apiBaseProjects
    root: apiBaseProjects
    byId: "#{apiBaseProjects}/:id"
  user_profiles:
    apiBase: apiBaseProfiles
    root: apiBaseProfiles
    byId: "#{apiBaseProfiles}/:id"
  company:
    apiBase: apiBaseCompanies
    root: apiBaseCompanies
    rootPost: apiBaseCompanies
    byId: "#{apiBaseCompanies}/:id"
    byIdWPerms: "#{apiBaseCompanies}/:id"
  us_states:
    apiBase: apiBaseUsStates
    root: apiBaseUsStates
    byId: "#{apiBaseUsStates}/:id"
  account_images:
    apiBase: apiBaseAccountImages
    root: apiBaseAccountImages
    byId: "#{apiBaseAccountImages}/:id"
  account_use_types:
    apiBase: apiBaseAccountUseTypes
    root: apiBaseAccountUseTypes
    byId: "#{apiBaseAccountUseTypes}/:id"
  version:
    version: "#{apiBase}/version"
  config:
    mapboxKey: "#{apiBase}/mapbox_key"
    cartodb: "#{apiBase}/cartodb"
    google: "#{apiBase}/google"
  properties:
    filterSummary: "#{apiBase}/properties/filter_summary/"
    parcelBase: "#{apiBase}/properties/parcel_base/"
    addresses: "#{apiBase}/properties/addresses/"
    detail: "#{apiBase}/properties/detail/"
    details: "#{apiBase}/properties/details/"
  snail:
    quote: "#{apiBase}/snail/quote"
    send: "#{apiBase}/snail/send"
  cartodb:
    getByFipsCodeAsFile: "#{apiBase}/cartodb/fipscodeFile/:fipscode"
    getByFipsCodeAsStream: "#{apiBase}/cartodb/fipscodeStream/:fipscode"
  parcel:
    getByFipsCode: "#{apiBase}/parcel"
    getByFipsCodeFormatted: "#{apiBase}/parcel/formatted"
    uploadToParcelsDb: "#{apiBase}/parcel/upload"
    defineImports: "#{apiBase}/parcel/defineimports"
  mls_config:
    apiBase: apiBaseMlsConfig # Exposed for Restangular instantiation
    root: apiBaseMlsConfig
    byId: "#{apiBaseMlsConfig}/:id"
    updatePropertyData: "#{apiBaseMlsConfig}/:id/propertyData"
    updateServerInfo: "#{apiBaseMlsConfig}/:id/serverInfo"

  mls:
    apiBaseMls: apiBaseMls # Exposed for Restangular instantiation
    getDatabaseList: "#{apiBaseMls}/:mlsId/databases"
    getTableList: "#{apiBaseMls}/:mlsId/databases/:databaseId/tables"
    getColumnList: "#{apiBaseMls}/:mlsId/databases/:databaseId/tables/:tableId/columns"
    getDataDump: "#{apiBaseMls}/:mlsId/data"
    getLookupTypes: "#{apiBaseMls}/:mlsId/databases/:databaseId/lookups/:lookupId/types"
  data_source:
    apiBaseDataSource: apiBaseDataSource
    apiBaseDataSourceLookups: apiBaseDataSourceLookups
    getColumnList: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/columns"
    getLookupTypes: "#{apiBaseDataSourceLookups}/:lookupId/types"
  data_source_rules:
    getRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules"
    createRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules"
    putRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules"
    deleteRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules"
    getListRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list"
    createListRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list"
    putListRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list"
    deleteListRules: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list"
    getRule: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list/:ordering"
    updateRule: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list/:ordering"
    deleteRule: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/rules/:list/:ordering"
  jobs:
    apiBase: apiBaseJobs
    taskHistory: "#{apiBaseJobs}/history"
    subtaskErrorHistory: "#{apiBaseJobs}/subtaskerrorhistory"
    queues: "#{apiBaseJobs}/queues/"
    queuesById: "#{apiBaseJobs}/queues/:name"
    tasks: "#{apiBaseJobs}/tasks"
    tasksById: "#{apiBaseJobs}/tasks/:name"
    subtasks: "#{apiBaseJobs}/subtasks"
    subtasksById: "#{apiBaseJobs}/subtasks/:name"
    summary: "#{apiBaseJobs}/summary"
    health: "#{apiBaseJobs}/health"
    runTask: "#{apiBaseJobs}/tasks/:name/run"
    cancelTask: "#{apiBaseJobs}/tasks/:name/cancel"
  mail:
    apiBaseMailCampaigns: apiBaseMailCampaigns
    root: apiBaseMailCampaigns
    byId: "#{apiBaseMailCampaigns}/:id"

  # hirefire secret value set from within backend/config/config.coffee
