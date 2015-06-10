app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNormalizeService', ['Restangular', (Restangular) ->

  getRules = (mlsId) ->
    Restangular.all('/api/mls_config').one(mlsId).all('rules').getList()

  service =
    getRules: getRules

  service
]