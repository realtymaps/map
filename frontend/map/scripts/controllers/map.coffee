app = require '../app.coffee'
require '../factories/map.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{Point, NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
{uiProfile} = require('../../../../common/utils/util.profile.coffee')

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

app.controller 'rmapsMapCtrl', ($scope, $rootScope, $location, $timeout, $http, rmapsMap,
  rmapsMainOptions, rmapsMapToggles, rmapsprincipal, rmapsevents,
  rmapsParcelEnums, rmapsProperties, $log, rmapssearchbox) ->

    $scope.selectProfile = (profile) ->
      $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)
      .then () ->
        loadProfile(profile)

    #ng-inits or inits
    #must be defined pronto as they will be skipped if you try to hook them to factories
    $scope.resultsInit = (resultsListId) ->
      $scope.resultsListId = resultsListId

    $scope.init = (pageClass) ->
      $scope.pageClass = pageClass
    #end inits

    rmapssearchbox('mainMap')

    $rootScope.registerScopeData () ->
      rmapsprincipal.getIdentity()
      .then (identity) ->
        $scope.projects = identity.profiles
        $scope.projectsTotal = (_.keys $scope.projects).length
        _.each $scope.projects, (project) ->
          project.totalPropertiesSelected = (_.keys project.propertiesSelected).length

        if not identity?.currentProfileId
          return $location.path(frontendRoutes.profiles)

        loadProfile uiProfile(identity)

    loadProfile = (profile) ->
      $rootScope.selectedFilters = {}

      map_position = profile.map_position
      #fix messed center
      if !map_position?.center?.lng or !map_position?.center?.lat
        map_position =
          center:
            lat: 26.129241
            lng: -81.782227
            zoom: 15

      map_position =
        center: NgLeafletCenter map_position.center

      if profile.filters
        statusList = profile.filters.status || []
        delete profile.filters.status
        for key,status of rmapsParcelEnums.status
          profile.filters[key] = (statusList.indexOf(status) > -1)
        _.extend($rootScope.selectedFilters, profile.filters)
      if map
        if map_position?.center?
          $scope.map.center = NgLeafletCenter(map_position.center or rmapsMainOptions.map.options.json.center)
        if map_position?.zoom?
          $scope.map.center.zoom = Number map_position.zoom
        $scope.rmapsMapToggles = new rmapsMapToggles(profile.map_toggles)
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
        rmapsMainOptions.map.toggles = new rmapsMapToggles(profile.map_toggles)
        map = new rmapsMap($scope, rmapsMainOptions.map)

        if profile.map_results?.selectedResultId? and map?
          $log.debug "attempting to reinstate selectedResult"
          rmapsProperties.getPropertyDetail(null,
            profile.map_results.selectedResultId,"all")
          .then (data) ->
            map.scope.selectedResult = _.extend map.scope.selectedResult or {}, data

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
