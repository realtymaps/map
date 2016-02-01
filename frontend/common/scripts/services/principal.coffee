# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
backendRoutes = require '../../../../common/config/routes.backend.coffee'
permissionsUtil = require '../../../../common/utils/permissions.coffee'
mod = require '../module.coffee'

mod.service 'rmapsPrincipalService', ($rootScope, $q, $http, rmapsevents) ->
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
      $rootScope.$emit rmapsevents.principal.login.success, identity

  unsetIdentity = () ->
    _identity = null
    _authenticated = false
    _resolved = false
    _isStaff = null

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
      defer.resolve null

    return defer.promise

  # Set the current profile and send an event to notify that the profile has been updated
  setCurrentProfile = (profile) ->
    _identity.currentProfileId = if profile then profile.id else null
    notifyProfileUpdated profile if profile

  getCurrentProfileId = () ->
    return getCurrentProfile()?.id

  getCurrentProfile = () ->
    return if _identity?.currentProfileId then _identity.profiles[_identity.currentProfileId] else null

  notifyProfileUpdated = (profile) ->
    $rootScope.$emit rmapsevents.principal.profile.updated, profile

  ##
  ##
  ## Public Service API
  ##
  ##

  isSubscriber: () ->
    return _identity and _identity.user?.parent_id == null

  isProjectEditor: () ->
    profile = getCurrentProfile()
    return profile and profile.parent_auth_user_id == null

  isProjectViewer: () ->
    profile = getCurrentProfile()
    return profile and profile.parent_auth_user_id != null

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
  getCurrentProfileId: getCurrentProfileId
  getCurrentProfile: getCurrentProfile
