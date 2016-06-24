app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{defer} = require '../../../../backend/extensions/promise.coffee' #TODO move to common

_stripeKeysDeferred = defer()
_stripeKeysPromise = _stripeKeysDeferred.promise

app.run ($http, $log) ->
  $http.get backendRoutes.config.safeConfig
  .then ({data}) ->
    if !data?.stripe?
      msg = "stripe setting undefined"
      $log.error msg
      _stripeKeysDeferred.reject new Error msg

    _stripeKeysDeferred.resolve data.stripe
  .catch _stripeKeysDeferred.reject


app.config (stripeProvider) ->
  _stripeKeysPromise
  .then (stripeKeys) ->
    stripeProvider.setPublishableKey stripeKeys.public_test_api_key
