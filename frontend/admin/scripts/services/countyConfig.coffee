app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
Promise = require 'bluebird'

app.service 'rmapsCountyService', [ 'Restangular', (Restangular) ->

  mlsAPI = backendRoutes.mls.apiBaseMls
  mlsConfigAPI = backendRoutes.mls_config.apiBase
  dataSourceAPI = backendRoutes.data_source.apiBaseDataSource

  # Hardcoding here for now, we may need to make a table for these later
  # This isn't really a "config", but rather the actual raw stuff this service handles, so no need to modularize it outside.
  countyData = [
    id: 'CoreLogic'
    name: 'CoreLogic'
    # listing_data: {} # I think exists only for MLS
    tax: {}
    deed: {}
  ]

  getConfigs = (params = {}) ->
    Promise.resolve(countyData)
#     Restangular.all(mlsConfigAPI).getList(params)

#   postConfig = (configObj, collection) ->
#     newMls = Restangular.one(mlsConfigAPI)
#     _.merge newMls, configObj
#     newMls.save().then (res) ->
#       # add to our collection (by reference, for adding to existing dropdowns, etc)
#       if collection
#         collection.push(newMls)
#       # for some reason even though we used save(), each subsequent .save() will keep trying posts, which inserts.
#       # this hack flags it to start using 'put' when saving from now on.
#       newMls.fromServer = true
#       newMls

#   postMainPropertyData = (configId, mainPropertyData) ->
#     Restangular.all(mlsConfigAPI).one(configId).all('propertyData').customPUT(mainPropertyData)

#   postServerData = (configId, serverData) ->
#     Restangular.all(mlsConfigAPI).one(configId).all('serverInfo').customPUT(serverData)

#   postServerPassword = (configId, password) ->
#     Restangular.all(mlsConfigAPI).one(configId).all('serverInfo').customPUT(password)

#   getDatabaseList = (configId) ->
#     Restangular.all(mlsAPI).one(configId).all('databases').getList()

#   getTableList = (configId, databaseId) ->
#     Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('tables').getList()

  getColumnList = (dataSourceId, dataSourceType, dataListType) ->
    console.log "#### rmapsCountyService.getColumnList()"
    Restangular.all(dataSourceAPI).one(dataSourceId).all('dataSourceType').one(dataSourceType).all('dataListType').one(dataListType).all('columns').getList()

  getLookupTypes = (configId, databaseId, lookupId) ->
    console.log "#### rmapsCountyService.getLookupTypes()"
    #Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('lookups').one(lookupId).all('types').getList()

#   getDataDumpUrl = (configId, limit) ->
#     # bypass XHR / $http file-dl drama, and Restangular req/res complication.
#     backendRoutes.mls.getDataDump.replace(':mlsId', configId) + "?limit=#{limit}"

  service =
    getConfigs: getConfigs
    # postConfig: postConfig,
    # postMainPropertyData: postMainPropertyData,
    # postServerData: postServerData,
    # postServerPassword: postServerPassword,
    # getDatabaseList: getDatabaseList,
    # getTableList: getTableList,
    getColumnList: getColumnList
    getLookupTypes: getLookupTypes
    # getDataDumpUrl: getDataDumpUrl

  service
]
