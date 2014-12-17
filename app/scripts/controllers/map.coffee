app = require '../app.coffee'
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
  '$scope', '$rootScope', 'Map'.ourNs(), 'MainOptions'.ourNs(), 'MapToggles'.ourNs(), 'principal'.ourNs(), 'events'.ourNs(), 'ParcelEnums'.ourNs(),
  ($scope, $rootScope, Map, MainOptions, Toggles, principal, Events, ParcelEnums) ->
    
    $scope.pageClass = 'page-map'

    map = new Map($scope, MainOptions.map)
    
    restoreState = () ->
      principal.getIdentity()
      .then (identity) ->
        if not identity?.stateRecall
          return
        if identity.stateRecall.map_center
          _.extend($scope.center, identity.stateRecall.map_center)
        if identity.stateRecall.map_zoom
          $scope.zoom = +identity.stateRecall.map_zoom
        if identity.stateRecall.filters
          filters = _.clone(identity.stateRecall.filters)
          statusList = filters.status || []
          delete filters.status
          for key,status of ParcelEnums.status
            filters[key] = (statusList.indexOf(status) > -1)
          if not $rootScope.selectedFilters?
            $rootScope.selectedFilters = {}
          _.extend($rootScope.selectedFilters, filters)

    $scope.$onRootScope Events.principal.login.success, () ->
      restoreState()
    
    if principal.isIdentityResolved() && principal.isAuthenticated()
      restoreState()

    $scope.Toggles = Toggles
]
