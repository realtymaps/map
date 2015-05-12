app = require '../app.coffee'
require '../factories/map.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
{Point, NgLeafletCenter} = require('../../../common/utils/util.geometries.coffee')


###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined

module.exports = app

#WE WILL STILL NEED THIS IN PRODUCTION FOR A GOOGLE APIKEY
#app.config(['uiGmapGoogleMapApiProvider', (GoogleMapApi) ->
#  GoogleMapApi.configure
#    # key: 'your api key',
#    v: '3.18'
#    libraries: 'visualization,geometry,places'
#])

app.controller 'rmapsMapCtrl', ($scope, $rootScope, $timeout, rmapsMap,
  rmapsMainOptions, rmapsMapToggles, rmapsprincipal, rmapsevents,
  rmapsParcelEnums, rmapsProperties, $log, rmapssearchbox) ->

    #ng-inits or inits
    #must be defined pronto as they will be skipped if you try to hook them to factories
    $scope.resultsInit = (resultsListId) ->
      $scope.resultsListId = resultsListId

    $scope.init = (pageClass) ->
      $scope.pageClass = pageClass
    #end inits

    rmapssearchbox('mainMap')

    restoreState = () ->
      rmapsprincipal.getIdentity()
      .then (identity) ->
        if not identity?.stateRecall
          return
        $rootScope.selectedFilters = {}

        map_position = identity.stateRecall.map_position
        #fix messed center
        if !map_position?.center?.lng or !map_position?.center?.lat
          map_position =
            center:
              lat: 26.129241
              lng: -81.782227
              zoom: 15

        map_position =
          center: NgLeafletCenter map_position.center

        if identity.stateRecall.filters
          statusList = identity.stateRecall.filters.status || []
          delete identity.stateRecall.filters.status
          for key,status of rmapsParcelEnums.status
            identity.stateRecall.filters[key] = (statusList.indexOf(status) > -1)
          _.extend($rootScope.selectedFilters, identity.stateRecall.filters)
        if map
          if map_position?.center?
            $scope.map.center = NgLeafletCenter(map_position.center or rmapsMainOptions.map.options.json.center)
          if map_position?.zoom?
            $scope.map.center.zoom = Number map_position.zoom
          $scope.rmapsMapToggles = new rmapsMapToggles(identity.stateRecall.map_toggles)
        else
          if map_position?
            if map_position.center? and
            map_position.center.latitude? and
            map_position.center.latitude != "NaN" and
            map_position.center.longitude? and
            map_position.center.longitude != "NaN"
              rmapsMainOptions.map.options.json.center = NgLeafletCenter map_position.center
            if map_position.zoom?
              rmapsMainOptions.map.options.json.center.zoom = +map_position.zoom
          rmapsMainOptions.map.toggles = new rmapsMapToggles(identity.stateRecall.map_toggles)
          map = new rmapsMap($scope, rmapsMainOptions.map)

          if identity.stateRecall.map_results?.selectedResultId? and map?
            $log.debug "attempting to reinstate selectedResult"
            rmapsProperties.getPropertyDetail(null,
              identity.stateRecall.map_results.selectedResultId,"all")
            .then (data) ->
              map.scope.selectedResult = _.extend map.scope.selectedResult or {}, data

    $scope.$onRootScope rmapsevents.principal.login.success, () ->
      restoreState()

    if rmapsprincipal.isIdentityResolved() && rmapsprincipal.isAuthenticated()
      restoreState()

# fix google map views after changing back to map state
app.run ($rootScope, $timeout) ->
    $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
      # if we're not entering the map state, or if we're already on the map state, don't do anything
      if toState.url != frontendRoutes.map || fromState.url == frontendRoutes.map
        return

      $timeout () ->
        # main map
        map?.scope.control.refresh?()
        # street view map -- TODO: this doesn't work for street view, not sure why
        gStrMap = map?.scope.controls.streetView.getGObject?()
        if gStrMap?
          google.maps.event.trigger(gStrMap, 'resize')
      , 500
