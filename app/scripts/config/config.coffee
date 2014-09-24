app = require '../app.coffee'

_this = app.config(['GoogleMapApiProvider'.ns(), (GoogleMapApi) ->
  GoogleMapApi.configure
  # key: 'your api key',
    v: '3.17' #note 3.16 is slow and buggy on markers
    libraries: 'weather,geometry,visualization,geometry'

]).config ['$locationProvider', ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.exports = _this
