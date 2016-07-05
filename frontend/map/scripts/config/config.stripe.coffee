app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{defer} = require '../../../../common/utils/util.promise.coffee'


_stripeKeysDeferred = defer()

app.run ($http, $log) ->
  $http.get backendRoutes.config.safeConfig
  .then ({data}) ->
    if !data?.stripe?
      msg = "stripe setting undefined"
      $log.error msg
      _stripeKeysDeferred.reject(new Error(msg))
      return
    _stripeKeysDeferred.resolve(data.stripe)
  .catch _stripeKeysDeferred.reject


app.config (stripeProvider) ->
  _stripeKeysDeferred.promise
  .then (stripeKeys) ->
    stripeProvider.setPublishableKey stripeKeys.public_test_api_key
