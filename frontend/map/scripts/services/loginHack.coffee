app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.service 'rmapsLoginHack', (
  $log
  $http
) ->
  $log = $log.spawn 'loginHack'
  #
  #
  # If this gets altered, ensure both rmapsLoginCtrl and rmapsClientEntryCtrl function properly
  #
  #


  ### BEGIN TERRIBLE HACK !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    We need to figure out why after login succedes that some post processing routes still think we are not logged in.

    Hence, why we check backendRoutes.userSession.profiles as this route is protected by login. We recurse this route until
    we are actually logged in.
  ###
  isLoggedIn = () ->
    $http.get backendRoutes.userSession.profiles
    .then ({data} = {}) ->
      if !data || data.doLogin == true
        return false
      true

  # just because loggin succeeded does not mean the backend is synced with the profile
  # check until it is synced
  checkLoggIn = (callback, maybeLoggedIn) ->
    if maybeLoggedIn
      callback()
      return

    isLoggedIn()
    .then (loggedIn) ->
      setTimeout ->
        checkLoggIn(callback, loggedIn)
      , 500

  # END TERRIBLE HACK !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  {
    checkLoggIn
  }
