app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsMlsService', ['Restangular', (Restangular) ->

  mlsRestangular = Restangular.all(backendRoutes.mls.apiBaseMls)
  mlsConfigRestangular = Restangular.all(backendRoutes.mls.apiBaseMlsConfig)

  getConfigs = () ->
    Restangular.all('/api/mls_config').getList()

  postConfig = (configObj, collection) ->
    newMls = Restangular.one('/api/mls_config')
    _.merge newMls, configObj
    newMls.post().then (res) ->
      # add to our collection (by reference, for adding to existing dropdowns, etc)
      if collection
        collection.push(newMls)
      newMls

  getDatabaseList = (configId) ->
    Restangular.all('/api/mls').one(configId).all('databases').getList()

  getTableList = (configId, databaseId) ->
    Restangular.all('/api/mls').one(configId).all('databases').one(databaseId).all('tables').getList()

  getColumnList = (configId, databaseId, tableId) ->
    Restangular.all('/api/mls').one(configId).all('databases').one(databaseId).all('tables').one(tableId).all('columns').getList()

  service =
    getConfigs: getConfigs,
    postConfig: postConfig,
    getDatabaseList: getDatabaseList,
    getTableList: getTableList,
    getColumnList: getColumnList

  service
]