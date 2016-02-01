mod = window.angular.module 'rmapsCommon', ['nemLogging']
module.exports = mod


mod.config (nemDebugProvider) ->
  debug = nemDebugProvider.debug
  debug.enable("common:*")


mod.run (rmapsUsStatesService, $rootScope) ->
  
  rmapsUsStatesService.getAll().then (states) ->
    $rootScope.us_states = states
