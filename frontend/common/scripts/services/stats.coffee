mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'


mod.service 'rmapsStatsService', ($http, $q) ->

  api = backendRoutes.stats

  signUps = (options) ->
    $http.getData(api.signUps, options)

  mailings = (options) ->
    $http.getData(api.mailings, options)

  return {
    signUps
    mailings
  }
