app = require '../app.coffee'
require '../factories/map.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined

module.exports = app

app.config(['uiGmapGoogleMapApiProvider', (GoogleMapApi) ->
  GoogleMapApi.configure
  # key: 'your api key',
    v: '3.17' #note 3.16 is slow and buggy on markers
    libraries: 'visualization,geometry,places'
])

app.controller 'MapCtrl'.ourNs(), [
  '$scope', '$rootScope', '$timeout', 'Map'.ourNs(), 'MainOptions'.ourNs(), 'MapToggles'.ourNs(),
  'principal'.ourNs(), 'events'.ourNs(), 'ParcelEnums'.ourNs(), 'Properties'.ourNs(),
  'Logger'.ourNs(),
  ($scope, $rootScope, $timeout, Map, MainOptions, Toggles,
  principal, Events, ParcelEnums, Properties, $log) ->
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
        map_position = identity.stateRecall.map_position

        if identity.stateRecall.filters
          statusList = identity.stateRecall.filters.status || []
          delete identity.stateRecall.filters.status
          for key,status of ParcelEnums.status
            identity.stateRecall.filters[key] = (statusList.indexOf(status) > -1)
          _.extend($rootScope.selectedFilters, identity.stateRecall.filters)
        if map
          if map_position?.center?
            $scope.center = map_position.center or MainOptions.map.options.json.center
          if map_position?.zoom?
            $scope.zoom = +map_position.zoom
          $scope.toggles = new Toggles(identity.stateRecall.map_toggles)
        else
          if map_position?
            if map_position.center? and
            map_position.center.latitude? and
            map_position.center.latitude != "NaN" and
            map_position.center.longitude? and
            map_position.center.longitude != "NaN"
              MainOptions.map.options.json.center = identity.stateRecall.map_position.center
            if map_position.zoom?
              MainOptions.map.options.json.zoom = +map_position.zoom
          MainOptions.map.toggles = new Toggles(identity.stateRecall.map_toggles)
          map = new Map($scope, MainOptions.map)

          if identity.stateRecall.map_results? and map?
            $log.debug "attempting to reinstate selectedResult"
            Properties.getPropertyDetail(null,
              identity.stateRecall.map_results.selectedResultId,"all")
            .then (data) ->
              map.scope.selectedResult = _.extend map.scope.selectedResult or {}, data

    $scope.$onRootScope Events.principal.login.success, () ->
      restoreState()

    if principal.isIdentityResolved() && principal.isAuthenticated()
      restoreState()
]

# fix google map views after changing back to map state
app.run ["$rootScope", "$timeout",
  ($rootScope, $timeout) ->
    $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
      # if we're not entering the map state, or if we're already on the map state, don't do anything
      if toState.url != frontendRoutes.map || fromState.url == frontendRoutes.map
        return

      console.log("============================================")
      $timeout () ->
        # main map
        gMap = map?.scope.control.getGMap?()
        if gMap?
          google.maps.event.trigger(gMap, 'resize')
        # satellite view map
        gSatMap = map?.scope.satMap?.control.getGMap?()
        if gSatMap?
          google.maps.event.trigger(gSatMap, 'resize')
        # street view map -- TODO: this doesn't work for street view, not sure why
        gStrMap = map?.scope.controls.streetView.getGObject?()
        if gStrMap?
          google.maps.event.trigger(gStrMap, 'resize')
      , 500
]
