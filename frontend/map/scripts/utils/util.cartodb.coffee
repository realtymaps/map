routes = require '../../../../common/config/routes.backend.coffee'
http = require './util.http.coffee'

baseRoute = routes.config.protectedConfig

wakeUp = (cartodb) ->
  cartodb?.WAKE_URLS?.forEach (url) ->
    #TODO: this call can dissapear if the job task of waking cartodb is fixed
    #needed to get around COORS same origin policy for now
    http.post {url, isAsync: true}

initCartodb = ($http) ->
  $http.getData baseRoute
  .then ({cartodb}) ->

    cartodb ?= {}

    wakeUp(cartodb)

    cartodb

initCartodb.baseRoute = baseRoute
initCartodb.wakeUp = wakeUp

module.exports = initCartodb
