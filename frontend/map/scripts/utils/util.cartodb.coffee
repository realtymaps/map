http = require './util.http.coffee'
routes = require '../../../../common/config/routes.backend.coffee'

baseRoute = routes.config.protectedConfig

wakeUp = (cartodb) ->
  if cartodb?.WAKE_URLS?
    cartodb.WAKE_URLS.forEach (url) ->
      http.post url, true

initCartodb = () ->
  try
    {cartodb} = JSON.parse http.get baseRoute

  cartodb ?= {}

  wakeUp(cartodb)

  cartodb

initCartodb.baseRoute = baseRoute
initCartodb.wakeUp = wakeUp

module.exports = initCartodb
