app = require '../app.coffee'
mainRun = require '../runners/run.map.coffee'

app.config (stripeProvider) ->
  mainRun.rootScopePromise
  .then ($rootScope) ->
    $rootScope.stripePromise
  .then (stripeKeys) ->
    stripeProvider.setPublishableKey stripeKeys.public_test_api_key
