module =  require '../module.coffee'

module.factory 'rmapsTempCacheFactory', ($q, $cacheFactory, $timeout) ->
  ({cacheName, cache}) ->
    cache ?= $cacheFactory.get(cacheName)

    ({url, promise, ttlMilliSec}) ->
      promise ?= $q.resolve()
      ttlMilliSec ?= 1000

      promise
      .then (result) ->
        $timeout () ->
          cache.remove(url)
        , ttlMilliSec
        result

module.service 'rmapsHttpTempCache', (rmapsTempCacheFactory, $http) ->
  rmapsTempCacheFactory(cacheName: '$http', cache: $http.defaults.cache)
