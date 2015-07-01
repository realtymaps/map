###
Object list of the defined routes. It's purpose is to keep the
frontend and backend in sync
###

apiBase = "/api"
apiBaseMls = "#{apiBase}/mls"
apiBaseMlsConfig = "#{apiBase}/mls_config"
apiBaseUsers = "#{apiBase}/users"
apiBaseSession = "#{apiBase}/session"

module.exports =
  views:
    rmap: "/rmap.html"
    admin: "/admin.html"
    mocksResults: "/mocks/results.html"
  wildcard:
    admin: "/admin/*"
    frontend: "/*"
    backend: "#{apiBase}/*"
  userSession:
    apiBase: apiBaseSession
    identity: "#{apiBaseSession}/identity"
    updateState: "#{apiBaseSession}/identity/state"
    login: "#{apiBaseSession}/login"
    logout: "#{apiBaseSession}/logout"
    currentProfile: "#{apiBaseSession}/currentProfile"
    profiles: "#{apiBaseSession}/profiles"
  user:
    apiBase: apiBaseUsers
    root: apiBaseUsers
    byId: "#{apiBaseUsers}/:id"
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

  # hirefire secret value set from within backend/config/config.coffee
