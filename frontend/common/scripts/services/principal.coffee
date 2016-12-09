# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
backendRoutes = require '../../../../common/config/routes.backend.coffee'
permissionsUtil = require '../../../../common/utils/permissions.coffee'
mod = require '../module.coffee'

mod.service 'rmapsPrincipalService', (
$rootScope, $q, $http, $log
rmapsEventConstants,
rmapsMainOptions) ->

  $log = $log.spawn 'principalService'
  #
  # Private Service Variables
  #
  _identity = null
  _authenticated = false
  _resolved = false
  _isStaff = null

  _identityPromise = null
  self = null #would use module.exports.. but it does not work
  #
  # Private Service Methods
  #

  addFrontendPermissions = () ->
    #This appears like your breaking single serving principal (one place to look)
    #However, it is not because the psuedo permissions below is being added so that the normal permissions work flow
    #works as is via route.coffee "permissionsRequired".
    for name in [
      "isSubscriber"
      "isProjectEditor"
      "isProjectViewer"
    ]
      do (name) ->
        if self[name](_identity)
          #We are stating here that because we are not a client account that we meet the permissions of isParentAccount
          _identity.permissions[name] = true

    if _identity.user?.mlses_verified?.length
      _identity.permissions.isMLS = true

    if _identity.user?.fips_codes?.length
      _identity.permissions.isFips = true

    _identity

  setIdentity = (identity) ->
    if identity != $rootScope.identity
      $log.debug 'Setting new identity on rootScope', identity
    _identity = identity
    $rootScope.identity = addFrontendPermissions()

    _authenticated = !!identity
    _resolved = true

    # Send an event to notify that the user is now authenticated
    if _authenticated
      $rootScope.$emit rmapsEventConstants.principal.login.success, identity

  unsetIdentity = () ->
    _identity = null
    _authenticated = false
    _resolved = false
    _isStaff = null
    $rootScope.identity = null
    $rootScope.$emit rmapsEventConstants.principal.logout.success

  # Returns a promise that is resolved/rejected based on the result of API call
  getIdentity = () ->
    # Use the in-memory _identity if available
    if _identity
      return $q.resolve _identity

    # otherwise, create a promise, retrieve the identity data from the server, update the identity object, and then resolve.
    if !_identityPromise
      defer = $q.defer()

      $http.get(backendRoutes.userSession.identity)
      .success (data) ->
        setIdentity data.identity
        _identityPromise = null
        defer.resolve data.identity
      .error (err) ->
        unsetIdentity()
        defer.reject null

      _identityPromise = defer.promise

    return _identityPromise

  # Set the current profile and send an event to notify that the profile has been updated
  setCurrentProfile = (profile) ->
    $log.debug 'Setting new currentProfile on identity', profile
    _identity.currentProfileId = if profile then profile.id else null
    _identity.currentProfile = if profile then _identity.profiles[profile.id] else null

  getCurrentProfileId = () ->
    return getCurrentProfile()?.id

  getCurrentProjectId = () ->
    return getCurrentProfile()?.project_id

  isCurrentProfileResolved = () ->
    _identity?.currentProfileId?

  getCurrentProfile = () ->
    if isCurrentProfileResolved()
      return _identity.profiles[_identity.currentProfileId]

  isSubscriber = () ->
    return (_identity and _identity.subscription? and
      _identity.subscription != 'canceled' and _identity.subscription != 'unpaid')

  # always implies an active subscription when set to 'pro' or 'standard'
  hasSubscription = (subscription) ->
    if !subscription?
      return _identity and (_identity.subscription == rmapsMainOptions.plan.PRO or _identity.subscription == rmapsMainOptions.plan.STANDARD)
    else
      return _identity and _identity.subscription == subscription

  isProjectEditor = () ->
    profile = getCurrentProfile()
    return profile?.can_edit

  isProjectViewer = () ->
    profile = getCurrentProfile()
    return profile?.parent_auth_user_id != null

  isIdentityResolved = () ->
    return _resolved

  isAuthenticated = () ->
    return _authenticated

  isMLS = () ->
    return _identity.permissions.isMLS == true

  hasPermission = (required) ->
    return _authenticated && permissionsUtil.checkAllowed(required, _identity.permissions)

  isInGroup = (group) ->
    return _authenticated && _identity.groups[group]

  isDebugEnvironment = () ->
    return _authenticated && _identity.environment == 'development'

  isStaff = () ->
    if !_isStaff? && _identity?
      _isStaff = permissionsUtil.checkAllowed('access_staff', _identity.permissions)
    return _authenticated && _isStaff

  ##
  ##
  ## Public Service API
  ##
  ##
  self = {
    isSubscriber
    hasSubscription
    isProjectEditor
    isProjectViewer
    isMLS

    isIdentityResolved
    isAuthenticated
    hasPermission
    isInGroup
    isDebugEnvironment
    isStaff
    isCurrentProfileResolved

    ##
    ## Query and Update Identity
    ##
    setIdentity
    unsetIdentity
    getIdentity

    ##
    ## Query and Update Profile / Project
    ##
    setCurrentProfile
    getCurrentProfile
    getCurrentProfileId
    getCurrentProjectId
  }
  return self
