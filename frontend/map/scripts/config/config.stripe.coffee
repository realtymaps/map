app = require '../app.coffee'
mainRun = require '../runners/run.map.coffee'

app.config (stripeProvider) ->
  mainRun.rootScopePromise
  .then ($rootScope) ->
    $rootScope.stripePromise
  .then (stripeKey) ->
    stripeProvider.setPublishableKey stripeKey
