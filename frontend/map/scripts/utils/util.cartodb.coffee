http = require './util.http.coffee'
routes = require '../../../../common/config/routes.backend.coffee'

try
  _cartodb = JSON.parse http.get routes.config.cartodb
catch

ret =  {}

ret = _cartodb if _cartodb
if _cartodb?.WAKE_URL?
  http.post _cartodb.WAKE_URL, true
module.exports = ret
