mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mod.config ($provide, nemSimpleLoggerProvider) ->
  $provide.decorator nemSimpleLoggerProvider.decorator...
.run (nemDebug, $http) ->
  $http.get(backendRoutes.config.debugLevels).then ({data}) ->
    nemDebug.enable data
