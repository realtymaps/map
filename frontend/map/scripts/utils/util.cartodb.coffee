http = require './util.http.coffee'
routes = require '../../../../common/config/routes.backend.coffee'

try
  _cartodb = JSON.parse http.get routes.config.cartodb
catch

ret =  {}

if _cartodb?
  root = "//#{_cartodb.ACCOUNT}.cartodb.com/api/v1"
  apiUrl = "api_key=#{_cartodb.API_KEY}"

  ret = _.extend _cartodb,
    tileUrl: "#{root}/map/{mapid}/{z}/{x}/{y}.png?#{apiUrl}"
    wakeUrl: "#{root}/map/named/#{_cartodb.TEMPLATE}?#{apiUrl}"

  http.post _cartodb.wakeUrl, true
module.exports = ret
