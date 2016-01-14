app = require '../app.coffee'
routes = require '../../../../common/config/routes.backend.coffee'
{defer} = require '../../../../backend/extensions/promise.coffee' #TODO move to common

_stripeKeysDeferred = defer()
_stripeKeysPromise = _stripeKeysDeferred.promise

app.run ($http) ->
  $http.get routes.config.stripe
  .then ({data}) ->
    _stripeKeysDeferred.resolve data
  .catch _stripeKeysDeferred.reject


app.config (stripeProvider) ->
  _stripeKeysPromise.then (stripeKeys) ->
    stripeProvider.setPublishableKey stripeKeys.public_test_api_key
