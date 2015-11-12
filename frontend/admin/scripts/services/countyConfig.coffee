app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
Promise = require 'bluebird'

app.service 'rmapsCountyService', [ '$log', 'Restangular', ($log, Restangular) ->

  mlsAPI = backendRoutes.mls.apiBaseMls
  mlsConfigAPI = backendRoutes.mls_config.apiBase
  dataSourceAPI = backendRoutes.data_source.apiBaseDataSource
  lookupAPI = backendRoutes.data_source.apiBaseDataSourceLookups

  # Hardcoding here for now, we may need to make a table for these later
  # This isn't really a "config", but rather the actual raw stuff this service handles, so no need to modularize it outside.
  countyData = [
    id: 'CoreLogic'
    name: 'CoreLogic'
  ]

  getConfigs = (params = {}) ->
    Promise.resolve(countyData)

  getColumnList = (dataSourceId, dataSourceType, dataListType) ->
    Restangular.all(dataSourceAPI).one(dataSourceId).all('dataSourceType').one(dataSourceType).all('dataListType').one(dataListType).all('columns').getList()

  getLookupTypes = (dataSourceId, lookupId) ->
    Restangular.all(lookupAPI).one(dataSourceId).all('lookupId').one(lookupId).getList('types')

  service =
    getConfigs: getConfigs
    getColumnList: getColumnList
    getLookupTypes: getLookupTypes

  service
]
