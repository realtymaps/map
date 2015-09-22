###
Object list of the defined routes. It's purpose is to keep the
frontend and backend in sync
###

apiBase = '/api'
apiBaseMls = "#{apiBase}/mls"
apiBaseMlsConfig = "#{apiBase}/mls_config"
apiBaseDataSource = "#{apiBase}/data_source"
apiBaseUsers = "#{apiBase}/users"
apiBaseUsersGroups = "#{apiBase}/usersGroups"
apiBaseGroups = "#{apiBase}/groups"
apiBaseGroupsPermissions = "#{apiBase}/groupsPermissions"
apiBasePermissions = "#{apiBase}/permissions"
apiBaseProjects = "#{apiBase}/projects"
apiBaseProfiles = "#{apiBase}/profiles"
apiBaseSession = "#{apiBase}/session"
apiBaseJobs = "#{apiBase}/jobs"
apiBaseCompanies = "#{apiBase}/companies"
apiBaseUsStates = "#{apiBase}/usStates"
apiBaseAccountUseTypes = "#{apiBase}/accountUseTypes"
apiBaseAccountImages = "#{apiBase}/accountImages"

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
    image: "#{apiBaseSession}/image"
    companyImage: "#{apiBaseSession}/companyImage/:account_image_id"
    root: apiBaseSession
    companyRoot: "#{apiBaseSession}/company"
    updatePassword: "#{apiBaseSession}/password"
    emailIsUnique: "#{apiBaseSession}/emailIsUnique"
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
  properties:
    filterSummary: "#{apiBase}/properties/filter_summary/"
    parcelBase: "#{apiBase}/properties/parcel_base/"
    addresses: "#{apiBase}/properties/addresses/"
    detail: "#{apiBase}/properties/detail/"
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
    getAll: "#{apiBaseMlsConfig}"
    create: "#{apiBaseMlsConfig}"
    getById: "#{apiBaseMlsConfig}/:id"
    update: "#{apiBaseMlsConfig}/:id"
    createById: "#{apiBaseMlsConfig}/:id"
    delete: "#{apiBaseMlsConfig}/:id"
    updatePropertyData: "#{apiBaseMlsConfig}/:id/propertyData"
    updateServerInfo: "#{apiBaseMlsConfig}/:id/serverInfo"


  mls_normalization:
    getMlsRules: "#{apiBaseMlsConfig}/:mlsId/rules"
    createMlsRules: "#{apiBaseMlsConfig}/:mlsId/rules"
    putMlsRules: "#{apiBaseMlsConfig}/:mlsId/rules"
    deleteMlsRules: "#{apiBaseMlsConfig}/:mlsId/rules"
    getListRules: "#{apiBaseMlsConfig}/:mlsId/rules/:list"
    createListRules: "#{apiBaseMlsConfig}/:mlsId/rules/:list"
    putListRules: "#{apiBaseMlsConfig}/:mlsId/rules/:list"
    deleteListRules: "#{apiBaseMlsConfig}/:mlsId/rules/:list"
    getRule: "#{apiBaseMlsConfig}/:mlsId/rules/:list/:ordering"
    updateRule: "#{apiBaseMlsConfig}/:mlsId/rules/:list/:ordering"
    deleteRule: "#{apiBaseMlsConfig}/:mlsId/rules/:list/:ordering"
  mls:
    apiBaseMls: apiBaseMls # Exposed for Restangular instantiation
    getDatabaseList: "#{apiBaseMls}/:mlsId/databases"
    getTableList: "#{apiBaseMls}/:mlsId/databases/:databaseId/tables"
    getColumnList: "#{apiBaseMls}/:mlsId/databases/:databaseId/tables/:tableId/columns"
    getDataDump: "#{apiBaseMls}/:mlsId/data"
    getLookupTypes: "#{apiBaseMls}/:mlsId/databases/:databaseId/lookups/:lookupId/types"
  data_source:
    apiBaseDataSource: apiBaseDataSource
    getColumnList: "#{apiBaseDataSource}/:dataSourceId/dataSourceType/:dataSourceType/dataListType/:dataListType/columns"
    getLookupTypes: "#{apiBaseDataSource}/:dataSourceId/sourceDataType/:sourceDataType/lookups/:lookupId/types"
    getDataDump: "#{apiBaseDataSource}/:dataSourceId/data"
  jobs:
    apiBase: apiBaseJobs
    taskHistory: "#{apiBaseJobs}/history"
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

  # hirefire secret value set from within backend/config/config.coffee
