mod = window.angular.module 'rmapsCommon', ['nemLogging']
module.exports = mod


mod.config (nemDebugProvider) ->
  debug = nemDebugProvider.debug
  debug.enable("common:*")


mod.run (rmapsUsStates, $rootScope) ->
  
  rmapsUsStates.getAll().then (states) ->
    $rootScope.us_states = states
