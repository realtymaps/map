app = require '../app.coffee'
require '../factories/map.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

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
    libraries: 'visualization,geometry,places'

])

.controller 'MapCtrl'.ourNs(), [
  '$scope', '$rootScope', 'Map'.ourNs(), 'MainOptions'.ourNs(), 'MapToggles'.ourNs(),
  'principal'.ourNs(), 'events'.ourNs(), 'ParcelEnums'.ourNs(),
  ($scope, $rootScope, Map, MainOptions, Toggles,
  principal, Events, ParcelEnums) ->
    #ng-inits or inits
    #must be defined pronto as they will be skipped if you try to hook them to factories
    $scope.resultsInit = (resultsListId) ->
      $scope.resultsListId = resultsListId

    $scope.init = (pageClass) ->
      $scope.pageClass = pageClass
    #end inits

    restoreState = () ->
      principal.getIdentity()
      .then (identity) ->
        if not identity?.stateRecall
          return
        $rootScope.selectedFilters = {}
        if identity.stateRecall.filters
          statusList = identity.stateRecall.filters.status || []
          delete identity.stateRecall.filters.status
          for key,status of ParcelEnums.status
            identity.stateRecall.filters[key] = (statusList.indexOf(status) > -1)
          _.extend($rootScope.selectedFilters, identity.stateRecall.filters)
        if map
          if identity.stateRecall.map_center
            $scope.center = identity.stateRecall.map_center or MainOptions.map.options.json.center
          if identity.stateRecall.map_zoom
            $scope.zoom = +identity.stateRecall.map_zoom
          $scope.toggles = new Toggles(identity.stateRecall.map_toggles)
        else
          if identity.stateRecall.map_center and
            identity.stateRecall.map_center.latitude? and
            identity.stateRecall.map_center.latitude != "NaN" and
            identity.stateRecall.map_center.longitude? and
            identity.stateRecall.map_center.longitude != "NaN"
              MainOptions.map.options.json.center = identity.stateRecall.map_center
          if identity.stateRecall.map_zoom
            MainOptions.map.options.json.zoom = +identity.stateRecall.map_zoom
          MainOptions.map.toggles = new Toggles(identity.stateRecall.map_toggles)
          map = new Map($scope, MainOptions.map)

    $scope.$onRootScope Events.principal.login.success, () ->
      restoreState()

    if principal.isIdentityResolved() && principal.isAuthenticated()
      restoreState()
]
