app = require '../app.coffee'
require '../factories/mainOptions.coffee'
require '../factories/map.coffee'

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined

module.exports = app

.config(['uiGmapGoogleMapApiProvider', (GoogleMapApi) ->
  GoogleMapApi.configure
  # key: 'your api key',
    v: '3.17' #note 3.16 is slow and buggy on markers
    libraries: 'visualization,geometry'

])

.controller 'MapCtrl'.ourNs(), [
  '$scope', 'Map'.ourNs(), 'MainOptions'.ourNs(), 'MapToggles'.ourNs(), "uiGmapLogger",
  ($scope, Map, PromisedOptions, Toggles, $log) ->
    $scope.pageClass = 'page-map'

    PromisedOptions.then (options) ->
      $log.doLog = options.options.doLog
      $log.currentLevel = options.options.logLevel

      map = unless map then new Map($scope, options) else map
    .catch (e) ->
      console.error e

    $scope.Toggles = Toggles
]

