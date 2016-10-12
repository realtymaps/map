app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.factory 'rmapsLoginService', ($http) ->

  @login = ({email, password}) ->
    $http.post(backendRoutes.userSession.login, {email, password})
  @
