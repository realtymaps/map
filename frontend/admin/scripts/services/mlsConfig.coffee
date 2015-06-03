app = require '../app.coffee'

app.service 'rmapsMlsService', (Restangular) ->
  getDatabaseList = (configId) ->
    Restangular.all('/api/mls').one(configId).all('databases').getList()

  getTableList = (configId, databaseName) ->
    Restangular.all('/ap/mls').one(configId).all('tables').getList
      databaseName: databaseName

  getFieldList = (configId, databaseName, tableName) ->
    Restangular.all('/api/mls').one(configId).all('columns').getList
      databaseName: databaseName,
      tableName: tableName
