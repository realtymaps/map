
{GOOGLE} = require './config'


keyParam = if GOOGLE?.MAPS?.API_KEY? then "key=#{GOOGLE.MAPS.API_KEY}&" else ""

module.exports =
  mapsSdkUrl = "http://maps.google.com/maps/api/js?v=3&#{keyParam}sensor=false"
