app = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.factory 'rmapsLoginService', ($http, $rootScope) ->

  @login = ({email, password, remember_me}) ->
    $http.post(backendRoutes.userSession.login, {email, password, remember_me})
  @
