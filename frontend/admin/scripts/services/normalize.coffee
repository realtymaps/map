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
