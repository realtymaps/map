app = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.factory 'rmapsLoginService', ($http, $rootScope) ->

  @login = ({email, password}) ->
    $http.post(backendRoutes.userSession.login, {email, password})
    .then (response) ->
      # setting user to $rootScope since this is where a reference to user is used in other parts of the app
      user = response.data.identity.user
      user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ''
      user.name = user.full_name or user.username
      $rootScope.user = user
      $rootScope.profiles = response.data.identity.profiles
      response

  @
