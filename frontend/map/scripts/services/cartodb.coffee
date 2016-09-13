routes = require '../../../../common/config/routes.backend.coffee'
http = require '../utils/util.http.coffee'
app = require '../app.coffee'

baseRoute = routes.config.protectedConfig

app.service 'rmapsCartoDb', ($http) ->
  wakeUp = (cartodb) ->
    cartodb?.WAKE_URLS?.forEach (url) ->
      #TODO: this call can dissapear if the job task of waking cartodb is fixed
      #needed to get around COORS same origin policy for now
      http.post {url, isAsync: true}

  init = () ->
    $http.getData baseRoute
    .then ({cartodb}) ->

      cartodb ?= {}

      wakeUp(cartodb)

      cartodb


  init()

  {
    baseRoute
    wakeUp
    init
  }
