app = require '../app.coffee'

#
# This service will track the prior state and parameters that were requested before the app redirects to
# the login page either because the user hasn't logged in yet or the backend session has expired
#
app.factory 'rmapsPriorStateService', ($log) ->
  $log = $log.spawn('map:rmapsPriorStateService')

  # Prior state/params objevct
  prior = null

  #
  # Service Definition
  #
  service =
    # Remember the prior state and params
    setPrior: (toState, toParams) ->
      $log.debug "Saving prior state '#{toState.name}'"
      prior = {
        state: toState,
        params: toParams
      }

    # Get the prior state and params as { state:, params: }
    # Prior may be null if never set
    getPrior: () ->
      return prior

    # Reset the prior state after a successful login
    clearPrior: () ->
      $log.debug "clearing prior state"
      prior = null

  return service
