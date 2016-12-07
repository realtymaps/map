###
Object list of the defined routes. It's purpose is to keep the
frontend and backend in sync
###

apiBase = '/api'
apiBaseMls = "#{apiBase}/mls"
apiBaseMlsConfig = "#{apiBase}/mls_config"
apiBaseConfig = "#{apiBase}/config"
apiBaseDataSource = "#{apiBase}/data_source"
apiBaseDataSourceLookups = "#{apiBase}/lookups"
apiBaseUsers = "#{apiBase}/users"
apiBaseUsersGroups = "#{apiBase}/usersGroups"
apiBaseClientEntry = "#{apiBase}/clientEntry"
apiBaseGroups = "#{apiBase}/groups"
apiBaseGroupsPermissions = "#{apiBase}/groupsPermissions"
apiBasePermissions = "#{apiBase}/permissions"
apiBaseProjects = "#{apiBase}/projects"
apiBaseUserSubscription = "#{apiBase}/subscription"
apiBaseUserSubscriptionPlan = "#{apiBase}/subscriptionPlan"
apiBaseDeactivateSubscription = "#{apiBase}/deactivateSubscription"
apiBaseSession = "#{apiBase}/session"
apiBaseJobs = "#{apiBase}/jobs"
apiBaseCompanies = "#{apiBase}/companies"
apiBaseFipsCodes = "#{apiBase}/fipsCodes"
apiBaseAccountUseTypes = "#{apiBase}/accountUseTypes"
apiBaseNotes = "#{apiBaseSession}/notes"
apiBaseMailCampaigns = "#{apiBase}/mailCampaigns"
apiBaseMailPdf = "#{apiBase}/mailPdf"
apiBaseProjectsSession = "#{apiBaseSession}/projects"
apiBasePlans = "#{apiBase}/plans"
apiBaseEmail = "#{apiBase}/email"
apiBaseOnboarding = "#{apiBase}/onboarding"
apiBaseWebhooks = "#{apiBase}/webhooks"
apiBaseCharges = "#{apiBase}/charges"
apiBasePaymentMethod = "#{apiBase}/paymentMethod"
apiBaseShell = "#{apiBase}/shell"
apiBasePhotos = "#{apiBase}/photos"
apiBasePrices = "#{apiBase}/prices"

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
    companyImage: "#{apiBaseSession}/companyImage"
    root: apiBaseSession
    companyRoot: "#{apiBaseSession}/company"
    updatePassword: "#{apiBaseSession}/password"
    requestResetPassword: "#{apiBaseSession}/requestResetPassword"
    getResetPassword: "#{apiBaseSession}/getResetPassword"
    doResetPassword: "#{apiBaseSession}/doResetPassword"
  notesSession:
    apiBase: apiBaseNotes
    root: apiBaseNotes
    byId: "#{apiBaseNotes}/:id"
  projectSession:
    apiBase: apiBaseProjectsSession
    root: apiBaseProjectsSession
    byId: "#{apiBaseProjectsSession}/:id"
    clients: "#{apiBaseProjectsSession}/:id/clients"
    clientsById: "#{apiBaseProjectsSession}/:id/clients/:clients_id"
    notes: "#{apiBaseProjectsSession}/:id/notes"
    notesById: "#{apiBaseProjectsSession}/:id/notes/:notes_id"
    drawnShapes: "#{apiBaseProjectsSession}/:id/drawnShapes"
    drawnShapesById: "#{apiBaseProjectsSession}/:id/drawnShapes/:drawn_shapes_id"
    #drawn shapes as areas
    areas: "#{apiBaseProjectsSession}/:id/areas"
  user:
    apiBase: apiBaseUsers
    root: apiBaseUsers
    byId: "#{apiBaseUsers}/:id"
    permissions: "#{apiBaseUsers}/:id/permissions"
    permissionsById: "#{apiBaseUsers}/:id/permissions/:permission_id"
    groups: "#{apiBaseUsers}/:id/groups"
    groupsById: "#{apiBaseUsers}/:id/groups/:group_id"
    image: "#{apiBaseUsers}/:id/image"
  clientEntry:
    getClientEntry: "#{apiBaseClientEntry}"
    setPasswordAndBounce: "#{apiBaseClientEntry}/login"
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
  user_subscription:
    apiBase: apiBaseUserSubscription
    getSubscription: apiBaseUserSubscription
    getPlan: apiBaseUserSubscriptionPlan
    setPlan: "#{apiBaseUserSubscriptionPlan}/:plan"
    deactivate: "#{apiBaseDeactivateSubscription}"
  company:
    apiBase: apiBaseCompanies
    root: apiBaseCompanies
    rootPost: apiBaseCompanies
    byId: "#{apiBaseCompanies}/:id"
    byIdWPerms: "#{apiBaseCompanies}/:id"
  fipsCodes:
    apiBase: apiBaseFipsCodes
    root: apiBaseFipsCodes
    byId: "#{apiBaseFipsCodes}/code/:code"
    getAll: "#{apiBaseFipsCodes}/state/:state"
    getAllMlsCodes: "#{apiBaseFipsCodes}/mls"
    getAllSupportedMlsCodes: "#{apiBaseFipsCodes}/mlsSupported"
    getForUser: "#{apiBaseFipsCodes}/user"
  account_use_types:
    apiBase: apiBaseAccountUseTypes
    root: apiBaseAccountUseTypes
    byId: "#{apiBaseAccountUseTypes}/:id"
  version:
    version: "#{apiBase}/version"
  config:
    apiBase: apiBaseConfig
    safeConfig: "#{apiBaseConfig}/safeConfig"
    protectedConfig: "#{apiBaseConfig}/protectedConfig"
  properties:
    mapState: "#{apiBase}/properties/mapState"
    filterSummary: "#{apiBase}/properties/filter_summary/"
    inArea: "#{apiBase}/properties/inArea/"
    inGeometry: "#{apiBase}/properties/inGeometry/"
    parcelBase: "#{apiBase}/properties/parcel_base/"
    addresses: "#{apiBase}/properties/addresses/"
    detail: "#{apiBase}/properties/detail/"
    details: "#{apiBase}/properties/details/"
    drawnShapes: "#{apiBase}/properties/drawnShapes/"
    saves: "#{apiBase}/properties/saves/"
    pin: "#{apiBase}/properties/pin/"
    unPin: "#{apiBase}/properties/unPin/"
    favorite: "#{apiBase}/properties/favorite/"
    unFavorite: "#{apiBase}/properties/unFavorite/"
    pva: "#{apiBase}/properties/pva/:fips_code"
  cartodb:
    getByFipsCodeAsFile: "#{apiBase}/cartodb/fipscodeFile/:fips_code"
    getByFipsCodeAsStream: "#{apiBase}/cartodb/fipscodeStream/:fips_code"
  mls_config:
    apiBase: apiBaseMlsConfig # Exposed for Restangular instantiation
    root: apiBaseMlsConfig
    byId: "#{apiBaseMlsConfig}/:id"
    updatePropertyData: "#{apiBaseMlsConfig}/:id/propertyData"
    updateServerInfo: "#{apiBaseMlsConfig}/:id/serverInfo"

  mls:
    apiBaseMls: apiBaseMls # Exposed for Restangular instantiation
    root: apiBaseMls
    activeAgent: "#{apiBaseMls}/agent"
    supported: "#{apiBaseMls}/supported"
    supportedStates: "#{apiBaseMls}/supported/states"
    supportedPossibleStates: "#{apiBaseMls}/supported/possible/states"
    getDatabaseList: "#{apiBaseMls}/:mlsId/databases"
    getTableList: "#{apiBaseMls}/:mlsId/databases/:databaseId/tables"
    getColumnList: "#{apiBaseMls}/:mlsId/databases/:databaseId/tables/:tableId/columns"
    getDataDump: "#{apiBaseMls}/:mlsId/:dataType/data"
    getLookupTypes: "#{apiBaseMls}/:mlsId/databases/:databaseId/lookups/:lookupId/types"
    getPhotos: "#{apiBaseMls}/:mlsId/databases/:databaseId/photos"
    getParamsPhotos: "#{apiBaseMls}/:mlsId/databases/:databaseId/photos/:photoIds"
    getObjectList: "#{apiBaseMls}/:mlsId/objects"
    getForUser: "#{apiBaseMls}/user"
    testOverlapSettings: "#{apiBaseMls}/:mlsId/overlap"
  data_source:
    apiBaseDataSource: apiBaseDataSource
    apiBaseDataSourceLookups: apiBaseDataSourceLookups
    getColumnList: "#{apiBaseDataSource}/:dataSourceId/dataListType/:dataListType/columns"
    getLookupTypes: "#{apiBaseDataSourceLookups}/:dataSourceId/dataListType/:dataListType/lookupId/:lookupId/types"
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
    sendCampaign: "#{apiBaseMailCampaigns}/:id/sendCampaign"
    getReviewDetails: "#{apiBaseMailCampaigns}/:id/review"
    #TODO: Why are the rest of these routes not a base of apiBaseMailCampaigns?
    getProperties: "#{apiBase}/getProperties/:project_id"
    getLetters: "#{apiBase}/getLetters"
    testLetter: "#{apiBase}/testLetter/:letter_id"
  pdfUpload:
    apiBaseMailPdf: apiBaseMailPdf
    root: apiBaseMailPdf
    byId: "#{apiBaseMailPdf}/:aws_key"
    validatePdf: "#{apiBaseMailPdf}/:aws_key/validate"
    getSignedUrl: "#{apiBaseMailPdf}/:aws_key/url"
  plans:
    apiBase: apiBasePlans
    root: apiBasePlans
  email:
    apiBase: apiBaseEmail
    verify: "#{apiBaseEmail}/:hash"
    isUnique: "#{apiBaseEmail}/isUnique"
    cancelPlan: "#{apiBaseEmail}/cancel/:hash"
  onboarding:
    apiBase: apiBaseOnboarding
    createUser: "#{apiBaseOnboarding}/createUser"
  webhooks:
    apiBase: apiBaseWebhooks
    stripe: "#{apiBaseWebhooks}/stripe"
    vero: "#{apiBaseWebhooks}/vero"
  charges:
    apiBase: apiBaseCharges
    getHistory: "#{apiBaseCharges}/history"
  paymentMethod:
    apiBase: apiBasePaymentMethod
    getDefaultSource: "#{apiBasePaymentMethod}/defaultsource"
    replaceDefaultSource: "#{apiBasePaymentMethod}/defaultsource/:source"
  shell:
    apiBase: apiBaseShell
    shell: apiBaseShell
  photos:
    apiBase: apiBasePhotos
    getResized: "#{apiBasePhotos}/resize"
  prices:
    apiBase: apiBasePrices
    mail: "#{apiBasePrices}/mail"

  # hirefire secret value set from within backend/config/config.coffee
