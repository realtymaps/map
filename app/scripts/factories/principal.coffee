# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication

app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'
permissionsUtil = require '../../../common/utils/permissions.coffee'


app.factory 'principal'.ourNs(), [
  '$rootScope', '$q', '$http', 'events'.ourNs(),
  ($rootScope, $q, $http, Events) ->
    _identity = null
    _authenticated = false
    _resolved = false
    _deferred = null
  
    setIdentity = (identity) ->
      _identity = identity
      _authenticated = !!identity
      _resolved = true
      if _deferred
        _deferred.resolve(identity)
        _deferred = null
      if _authenticated
        $rootScope.$emit Events.principal.login.success
    unsetIdentity = () ->
      _identity = null
      _authenticated = false
      _resolved = false
      if _deferred
        _deferred.resolve(null)
        _deferred = null
    
    isIdentityResolved: () ->
      return _resolved
    isAuthenticated: () ->
      return _authenticated
    hasPermission: (required) ->
      return _authenticated && permissionsUtil.checkAllowed(required,_identity.permissions)
    isInGroup: (group) ->
      return _authenticated && _identity.groups[group]
    setIdentity: setIdentity
    unsetIdentity: unsetIdentity
    getIdentity: () ->
      if _deferred
        return _deferred.promise
        
      if _resolved
        _deferred = $q.defer()
        _deferred.resolve(_identity)
        return _deferred.promise
  
      # otherwise, create a promise, retrieve the identity data from the server, update the identity object, and then resolve.
      _deferred = $q.defer();
      
      $http.get(backendRoutes.identity)
      .success (data) ->
        setIdentity(data.identity)
      .error (err) ->
        unsetIdentity()
        
      return _deferred.promise
]
