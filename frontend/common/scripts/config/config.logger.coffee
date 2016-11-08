mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mod.config ($provide, nemSimpleLoggerProvider) ->
  $provide.decorator('$log', ['$delegate', nemSimpleLoggerProvider.decorator[1]]) # todo: fix angular-simple-logger annotation
.run ($http, $log) ->
  $http.get(backendRoutes.config.safeConfig, cache: true).then ({data}) ->
    data = data.debugLevels
    unless typeof data == 'string'
      $log.error "debugLevels: #{JSON.stringify data}"
      return
    $log.enable(data, absoluteNamespace: true)
    $log = $log.spawn("common:run:loggerSetup")
    $log.debug "debug log namespace toggles: #{data}"
