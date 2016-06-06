# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
backendRoutes = require '../../../../common/config/routes.backend.coffee'
permissionsUtil = require '../../../../common/utils/permissions.coffee'
mod = require '../module.coffee'

mod.service 'rmapsPrincipalService', ($rootScope, $q, $http, rmapsEventConstants) ->
  #
  # Private Service Variables
  #
  _identity = null
  _authenticated = false
  _resolved = false
  _isStaff = null

  #
  # Private Service Methods
  #

  setIdentity = (identity) ->
    _identity = identity
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
    $rootScope.$emit rmapsEventConstants.principal.logout.success

  # Returns a promise that is resolved/rejected based on the result of API call
  getIdentity = () ->
    # Use the in-memory _identity if available
    if _identity
      return $q.resolve _identity

    # otherwise, create a promise, retrieve the identity data from the server, update the identity object, and then resolve.
    defer = $q.defer()

    $http.get(backendRoutes.userSession.identity)
    .success (data) ->
      setIdentity data.identity
      defer.resolve data.identity
    .error (err) ->
      unsetIdentity()
      defer.reject null

    return defer.promise

  # Set the current profile and send an event to notify that the profile has been updated
  setCurrentProfile = (profile) ->
    _identity.currentProfileId = if profile then profile.id else null
    notifyProfileUpdated profile if profile

  getCurrentProfileId = () ->
    return getCurrentProfile()?.id

  getCurrentProjectId = () ->
    return getCurrentProfile()?.project_id

  isCurrentProfileResolved = () ->
    _identity?.currentProfileId?

  getCurrentProfile = () ->
    if isCurrentProfileResolved()
      return _identity.profiles[_identity.currentProfileId]

  notifyProfileUpdated = (profile) ->
    $rootScope.$emit rmapsEventConstants.principal.profile.updated, profile

  ##
  ##
  ## Public Service API
  ##
  ##

  isSubscriber: () ->
    console.log "isSubscriber()\n_identity.subscription:#{_identity.subscription}"
    return (_identity and _identity.subscription? and
      _identity.subscription != 'canceled' and _identity.subscription != 'unpaid')

  # always implies an active subscription when set to 'pro' or 'standard'
  hasSubscription: (subscription) ->
    if !subscription?
      return _identity and (_identity.subscription == 'pro' or _identity.subscription == 'standard')
    else
      return _identity and _identity.subscription == subscription

  isProjectEditor: () ->
    profile = getCurrentProfile()
    return profile?.can_edit

  isProjectViewer: () ->
    profile = getCurrentProfile()
    return profile?.parent_auth_user_id != null

  isIdentityResolved: () ->
    return _resolved

  isAuthenticated: () ->
    return _authenticated

  hasPermission: (required) ->
    return _authenticated && permissionsUtil.checkAllowed(required, _identity.permissions)

  isInGroup: (group) ->
    return _authenticated && _identity.groups[group]

  isDebugEnvironment: () ->
    return _authenticated && _identity.environment == 'development'

  isStaff: () ->
    if !_isStaff? && _identity?
      _isStaff = permissionsUtil.checkAllowed('access_staff', _identity.permissions)
    return _authenticated && _isStaff

  isCurrentProfileResolved: isCurrentProfileResolved
  ##
  ## Query and Update Identity
  ##

  setIdentity: setIdentity
  unsetIdentity: unsetIdentity
  getIdentity: getIdentity

  ##
  ## Query and Update Profile / Project
  ##

  setCurrentProfile: setCurrentProfile
  getCurrentProfile: getCurrentProfile
  getCurrentProfileId: getCurrentProfileId
  getCurrentProjectId: getCurrentProjectId

