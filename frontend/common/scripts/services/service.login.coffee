app = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.factory 'rmapsLoginService', ($http, $rootScope) ->

  @login = (loginObj) ->
    $http.post(backendRoutes.userSession.login, loginObj)
  @
