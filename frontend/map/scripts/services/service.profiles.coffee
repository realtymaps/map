_ = require 'lodash'
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'project_id']
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')


app.service 'rmapsProfilesService', (
  $http
  $log
  $q
  $timeout
  $rootScope
  rmapsEventConstants
  rmapsMainOptions
  rmapsCurrentMapService
  rmapsMapTogglesFactory
  rmapsParcelEnums
  rmapsPrincipalService
  rmapsPropertiesService
  rmapsFiltersFactory
) ->

  $log = $log.spawn "rmapsProfilesService"

  #
  # Private functions
  #

  _update = (profile) ->
    $http.put(backendRoutes.userSession.profiles,_.pick(profile, _updateProfileAttrs))

  _current = (profile) ->
    $log.debug 'attempting to set current profile'
    $http.post(backendRoutes.userSession.currentProfile, {currentProfileId: profile.id}, {cache: false})
    .then ({data}) ->
      $log.debug 'set profile'
      $log.debug profile

      # Ensure profile timestamp is up-to-date
      if data.identity?.profiles?[profile.id]
        profile.rm_modified_time = data.identity.profiles[profile.id].rm_modified_time

      service.currentProfile = profile
      rmapsPrincipalService.setCurrentProfile profile

  # IMPORTANT we need to unset the current profile upon logout
  # otherwise upon login we would try to reuse the existing / dead profile
  # if we don't then identity's currentProfileId is never set and thus getCurrentProfile is null
  _unsetCurrent = () ->
    service.currentProfile = null

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

    unsetCurrentProfile: () ->
      _unsetCurrent()

    resetSyncFlags: () ->
      _isSettingProfile = false
      _settingCurrentPromise = null

    setCurrentProfileByProjectId: (project_id) ->
      project_id = Number(project_id) if _.isString project_id
      rmapsPrincipalService.getIdentity()
      .then (identity) =>
        if identity
          profile = _.find(identity.profiles, project_id: project_id)
          return @setCurrentProfile profile, updateIdentity: false

    setCurrentProfileByProfileId: (profile_id) ->
      profile_id = Number(profile_id) if _.isString profile_id
      rmapsPrincipalService.getIdentity()
      .then (identity) =>
        if identity
          profile = (_.find(identity.profiles, id: profile_id))
          return @setCurrentProfile profile, updateIdentity: false

    setCurrentProfileByIdentity: (identity) ->
      if identity.currentProfileId?
        return @setCurrentProfileByProfileId identity.currentProfileId
      else
        # open most recently modified
        return @setCurrentProfile(_.sortByOrder(_.values(identity.profiles), 'rm_modified_time','desc')[0], updateIdentity: false)




    ###
      Public: This function gets hammered by watchers and or page resolves at boot.
        Therefore we have a few GTFOS
    ###
    setCurrentProfile: (profile, opts={updateIdentity: true}) ->
      # GTFO 1
      if profile == @currentProfile
        $log.debug "Profile is already set as current profile, returning"
        return $q.resolve profile

      # GTFO 2
      # At boot @currentProfile is null and gets piled up on the Promise queue
      # if this does not exist
      if _isSettingProfile
        $log.debug "detected `_isSettingProfile`, returning `_settingCurrentPromise`"
        return _settingCurrentPromise

      # Get reference to the current main map
      currentMap = rmapsCurrentMapService.get()

      # ---------- Begin previous profile update
      #
      # This code updates the previous profile (the one we are switching away from),
      # which needs to happen BEFORE saving it to the backend via _setCurrent()
      # For some reason this had been moved after the backend call, but I can't figure out why - JCS
      #
      if @currentProfile
        $log.debug "detected @currentProfile, populating..."
        @currentProfile.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
        @currentProfile.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? && status
        @currentProfile.pins = _.mapValues rmapsPropertiesService.pins, 'savedDetails'

        # Get the center of the main map if it has been created
        $log.debug "rmapsCurrentMap: #{currentMap}"
        if currentMap
          @currentProfile.map_position = center: NgLeafletCenter(_.pick currentMap.scope?.map?.center, ['lat', 'lng', 'zoom'])
          if opts.updateIdentity
            # keep identity objects up-to-date since certain methods still pull profiles/projects from there
            rmapsPrincipalService.getIdentity()
            .then (identity) ->
              identity.profiles[@currentProfile.id] = @currentProfile

      #
      # ---------- End previous profile update
      #

      # Save the old and load the new profiles
      $log.debug "calling _setCurrent..."
      return _setCurrent @currentProfile, profile
      .then () ->
        service.loadProfile(profile)

    loadProfile: (profile) ->
      # Get reference to the current main map
      currentMap = rmapsCurrentMapService.get()

      if !profile?.map_position?.center?
        # bad things happen if we get this far w/o a map_position.center.  It should currently be accounted for in
        # backend when creating new profiles/projects
        $log.warn "Current profile has no map position!"
        return

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

      if currentMap?.scope?.map?
        ### eslint-disable###
        oldCenter = _.extend {}, currentMap?.scope?.map?.center
        ### eslint-enable###
        if map_position?.center?
          newCenter = NgLeafletCenter(map_position.center || rmapsMainOptions.map.options.json.center)
          newCenter.docWhere = 'rmapsProfilesService currentMainMap'
          if !newCenter.isEqual(currentMap.scope.map.center)
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
      profile.filters ?= {}

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

      if currentMap?
        $log.debug "Profile change, updating current map Toggles"
        currentMap.updateToggles profile.map_toggles
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
