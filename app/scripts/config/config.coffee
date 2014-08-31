app = require '../app.coffee'

_this = app.config(["GoogleMapApiProvider".ns(), (GoogleMapApi) ->
  GoogleMapApi.configure
  # key: 'your api key',
    v: "3.16"
    libraries: "weather,geometry,visualization"

]).config ['$locationProvider', ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.exports = _this

