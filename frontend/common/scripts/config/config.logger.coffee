mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mod.config ($provide, nemSimpleLoggerProvider) ->
  $provide.decorator nemSimpleLoggerProvider.decorator...
.run (nemDebug, $http, $log) ->
  $log = $log.spawn("frontend:common:run:loggerSetup")
  $http.get(backendRoutes.config.debugLevels).then ({data}) ->
    unless typeof data == 'string'
      $log.error "debugLevels: #{JSON.stringify data}"
      return
    nemDebug.enable data
    $log.debug "enabled: #{data} debug log levels."
