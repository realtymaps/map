http = require './util.http.coffee'
routes = require '../../../../common/config/routes.backend.coffee'

module.exports = ->
  try
      _cartodb = JSON.parse http.get routes.config.cartodb
  catch

  ret =  {}

  ret = _cartodb if _cartodb
  if _cartodb?.WAKE_URLS?
      _cartodb.WAKE_URLS.forEach (url) ->
          http.post url, true
  ret
