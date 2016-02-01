mod = window.angular.module 'rmapsCommon', ['nemLogging']
module.exports = mod


mod.config (nemDebugProvider) ->
  debug = nemDebugProvider.debug
  # TODO: isn't this a bad idea?  I think that enables *just* `common:*`, meaning it turns off anything that was turned
  # TODO: on in config, saved only by a race condition because this gets overridden when the logging config is retrieved
  # TODO: from the server
  debug.enable("common:*")


mod.run (rmapsUsStates, $rootScope) ->

  rmapsUsStates.getAll().then (states) ->
    $rootScope.us_states = states
