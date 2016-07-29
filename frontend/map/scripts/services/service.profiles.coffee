###global _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'project_id']
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')


app.service 'rmapsCurrentProfilesService', (
$http
rmapsHttpTempCache
) ->

  setCurrent: (profile) ->
    url = backendRoutes.userSession.currentProfile

    rmapsHttpTempCache {
      url
      promise: $http.post(url, {currentProfileId: profile.id}, {cache: true})
    }

app.service 'rmapsProfilesService', (
  $http
  $log
  $q
  $timeout
  $rootScope
  rmapsCurrentProfilesService
  rmapsEventConstants
  rmapsMainOptions
  rmapsMapFactory
  rmapsMapTogglesFactory
  rmapsParcelEnums
  rmapsPrincipalService
  rmapsPropertiesService
  rmapsFiltersFactory
) ->

  $log = $log.spawn "rmapsProfileService"

  #
  # Private functions
  #

  _update = (profile) ->
    $http.put(backendRoutes.userSession.profiles,_.pick(profile, _updateProfileAttrs))

  _current = (profile) ->
    $log.debug 'attempting to set current profile'
    rmapsCurrentProfilesService.setCurrent profile
    .then () ->
      $log.debug 'set profile'
      $log.debug profile
      service.currentProfile = profile
      rmapsPrincipalService.setCurrentProfile profile

  _isSettingProfile = false
  _settingCurrentPromise = null

  _setCurrent = (oldProfile, newProfile) ->
    _isSettingProfile = true

    _settingCurrentPromise = if oldProfile?
      $log.debug 'updating old profile'
      _update(oldProfile)
      .then () ->
        _current newProfile
    else
      _current newProfile

    _settingCurrentPromise.then () ->
      _isSettingProfile = false
      _settingCurrentPromise = null

    return _settingCurrentPromise

  #
  # Service Definition
  #

  service =
    currentProfile: null

    setCurrentProfileByProjectId: (project_id) ->
      project_id = Number(project_id) if _.isString project_id
      rmapsPrincipalService.getIdentity()
      .then (identity) =>
        if identity
          profile = (_.find(identity.profiles, project_id: project_id))
          return @setCurrentProfile profile

    setCurrentProfileByProfileId: (profile_id) ->
      profile_id = Number(profile_id) if _.isString profile_id
      rmapsPrincipalService.getIdentity()
      .then (identity) =>
        if identity
          profile = (_.find(identity.profiles, id: profile_id))
          return @setCurrentProfile profile

    setCurrentProfileByIdentity: (identity) ->
      if identity.currentProfileId?
        return @setCurrentProfileByProfileId identity.currentProfileId
      else
        return @setCurrentProfile _.values(identity.profiles)[0]

    ###
      Public: This function gets hammered by watchers and or page resolves at boot.
        Therefore we have a few GTFOS
    ###
    setCurrentProfile: (profile) ->
      # GTFO 1
      if profile == @currentProfile || profile?.id == @currentProfile?.id
        $log.debug "Profile is already set as current profile, returning"
        return $q.resolve profile

      # GTFO 2
      # At boot @currentProfile is null and gets piled up on the Promise queue
      # if this does not exist
      if _isSettingProfile
        return _settingCurrentPromise

      # If switching profiles, ensure the old one is up-to-date
      if @currentProfile
        @currentProfile.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
        @currentProfile.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? && status
        @currentProfile.pins = _.mapValues rmapsPropertiesService.pins, 'savedDetails'

        # Get the center of the main map if it has been created
        if rmapsMapFactory.currentMainMap
          @currentProfile.map_position = center: NgLeafletCenter(_.pick rmapsMapFactory.currentMainMap.scope?.map?.center, ['lat', 'lng', 'zoom'])

      # Save the old and load the new profiles
      return _setCurrent @currentProfile, profile
      .then () ->
        return if !profile?.map_position?.center?

        $log.debug "Set current profile to: #{profile.id}"

        # Center and zoom the map for the new profile
        map_position = center: NgLeafletCenter profile.map_position.center
        map_position.center.docWhere = 'rmapsProfilesService:profile.map_position.center'
        #
        # Center and zoom map to profile
        #

        #fix messed center
        if !map_position?.center?.lng || !map_position?.center?.lat
          map_position = rmapsMainOptions.map.options.json.center
          map_position.center.docWhere = 'rmapsProfilesService:invalid'

        if rmapsMapFactory.currentMainMap?.scope?.map?
          ### eslint-disable###
          oldCenter = _.extend {}, rmapsMapFactory?.currentMainMap?.scope?.map?.center
          ### eslint-enable###
          if map_position?.center?
            newCenter = NgLeafletCenter(map_position.center || rmapsMainOptions.map.options.json.center)
            newCenter.docWhere = 'rmapsProfilesService currentMainMap'
            if !newCenter.isEqual(rmapsMapFactory.currentMainMap.scope.map.center)
              $log.debug "Profile changed and map factory exists, recentering map"
              $log.debug "old lat: #{oldCenter.lat}, new lat: #{map_position.center.lat}"
              $log.debug "old lon: #{oldCenter.lon}, new lon: #{map_position.center.lon}"
              $log.debug "old zoom: #{oldCenter.zoom}, new zoom: #{map_position.center.zoom}"
              rmapsMainOptions.map.options.json.center = newCenter
        else
          if map_position?
            $log.debug "Profile set first time, recentering map"
            if map_position.center? &&
            map_position.center.latitude? &&
            map_position.center.latitude != 'NaN' &&
            map_position.center.longitude? &&
            map_position.center.longitude != 'NaN'
              newCenter = NgLeafletCenter map_position.center
              newCenter.docWhere = 'rmapsProfilesService original'
              rmapsMainOptions.map.options.json.center = newCenter

        # Handle profile filters
        #

        selectedFilters = _.defaults {}, profile.filters, rmapsFiltersFactory.valueDefaults
        delete selectedFilters.status
        delete selectedFilters.current_project_id

        $log.debug selectedFilters

        statusList = profile.filters?.status || []
        for key,status of rmapsParcelEnums.status
          selectedFilters[key] = (statusList.indexOf(status) > -1) || (statusList.indexOf(key) > -1)
        #TODO: this is a really ugly hack to workaround our poor state design in our app
        #filters and mapState need to be combined, also both should be moved to rootScope
        #the omits here are to keep from saving off duplicate data where selectedFilters is from the backend

        # Some parts of the UI expect a Date object
        if selectedFilters.closeDateMin
          selectedFilters.closeDateMin = new Date(selectedFilters.closeDateMin)
        if selectedFilters.closeDateMax
          selectedFilters.closeDateMax = new Date(selectedFilters.closeDateMax)

        $rootScope.selectedFilters = selectedFilters

        #
        # Set the Filter toggles based on the current profile
        #

        if rmapsMapFactory.currentMainMap?
          $log.debug "Profile change, updating current map Toggles"
          rmapsMapFactory.currentMainMap.updateToggles profile.map_toggles
        else
          $log.debug "Initial profile set, create Map Toggles Factory"
          rmapsMainOptions.map.toggles = new rmapsMapTogglesFactory(profile.map_toggles)

        return profile

  #
  # Listen for login event to ensure that a current profile is set
  #
  $rootScope.$onRootScope rmapsEventConstants.principal.login.success, (event, identity) ->
    service.setCurrentProfileByIdentity(identity)

  return service
