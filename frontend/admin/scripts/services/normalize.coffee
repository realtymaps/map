app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNormalizeService', ['Restangular', (Restangular) ->

  mlsConfigAPI = backendRoutes.mls_config.apiBaseMlsConfig

  getRules = (mlsId) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').getList()

  updateRule = (mlsId, rule) ->
    Restangular.all(mlsConfigAPI).one(mlsId).all('rules').one(rule.list).one(String(rule.ordering)).patch
      input: JSON.stringify(rule.input) # ensure strings are quoted
      config: rule.config
      transform: rule.transform

  service =
    getRules: getRules
    updateRule: updateRule
]
