app = require '../app.coffee'

app.service 'rmapsMlsService', ['Restangular', (Restangular) ->

  getConfigs = () ->
    Restangular.all('/api/mls_config').getList()

  getDatabaseList = (configId) ->
    Restangular.all('/api/mls').one(configId).all('databases').getList()

  getTableList = (configId, databaseName) ->
    Restangular.all('/ap/mls').one(configId).all('tables').getList
      databaseName: databaseName

  getColumnList = (configId, databaseName, tableName) ->
    Restangular.all('/api/mls').one(configId).all('columns').getList
      databaseName: databaseName,
      tableName: tableName

  service =
    getConfigs: getConfigs,
    getDatabaseList: getDatabaseList,
    getTableList: getTableList,
    getColumnList: getColumnList

  service
]
