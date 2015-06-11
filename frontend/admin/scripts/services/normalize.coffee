app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNormalizeService', ['Restangular', (Restangular) ->

  mlsConfigAPI = backendRoutes.mls_config.apiBaseMlsConfig

  getRules = (mlsId) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').getList()

  postRule = (ruleObj, ruleCollection) ->
    if not ruleCollection
      ruleCollection = Restangular.all(mlsConfigAPI).one(mlsId).all('rules')
    ruleCollection.post(ruleObj)
    .then (res) ->
      ruleCollection

  postRules = (mlsId, ruleObjs, ruleCollection) ->
    if not ruleCollection
      ruleCollection = Restangular.all(mlsConfigAPI).one(mlsId).all('rules')
    ruleCollection.customPOST(ruleObjs)
    .then (res) ->
      ruleCollection

  putRules = (mlsId, ruleObjs, ruleCollection) ->
    if not ruleCollection
      ruleCollection = Restangular.all(mlsConfigAPI).one(mlsId).all('rules')
    ruleCollection.customPUT(ruleObjs)
    .then (res) ->
      ruleCollection

  deleteRules = (mlsId) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').remove()

  getListRules = (mlsId, list) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(list).getList()

  postListRules = (mlsId, list, ruleObjs) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(list).customPOST(ruleObjs)

  putListRules = (mlsId, list, ruleObjs) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(list).customPUT(ruleObjs)

  deleteListRules = (mlsId, list) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(list).remove()


  service =
    getRules: getRules
    postRule: postRule
    postRules: postRules
    putRules: putRules
    deleteRules: deleteRules

    getListRules: getListRules
    postListRules: postListRules
    putListRules: putListRules
    deleteListRules: deleteListRules

  service
]



# app = require '../app.coffee'
# backendRoutes = require '../../../../common/config/routes.backend.coffee'

# app.service 'rmapsMlsService', ['Restangular', (Restangular) ->

#   mlsAPI = backendRoutes.mls.apiBaseMls
#   mlsConfigAPI = backendRoutes.mls_config.apiBaseMlsConfig

#   getConfigs = () ->
#     Restangular.all(mlsConfigAPI).getList()

#   postConfig = (configObj, collection) ->
#     newMls = Restangular.one(mlsConfigAPI)
#     _.merge newMls, configObj
#     newMls.post().then (res) ->
#       # add to our collection (by reference, for adding to existing dropdowns, etc)
#       if collection
#         collection.push(newMls)
#       newMls

#   getDatabaseList = (configId) ->
#     Restangular.all(mlsAPI).one(configId).all('databases').getList()

#   getTableList = (configId, databaseId) ->
#     Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('tables').getList()

#   getColumnList = (configId, databaseId, tableId) ->
#     Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('tables').one(tableId).all('columns').getList()

#   service =
#     getConfigs: getConfigs,
#     postConfig: postConfig,
#     getDatabaseList: getDatabaseList,
#     getTableList: getTableList,
#     getColumnList: getColumnList

#   service
# ]