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

module.service 'rmapsHttpTempCache', (rmapsEventConstants, rmapsTempCacheFactory, $cacheFactory, $http, $rootScope, $log) ->
  $log = $log.spawn 'rmapsHttpTempCache'

  service = rmapsTempCacheFactory(cacheName: '$http', cache: $http.defaults.cache)

  ## Clear the HTTP cache on logout
  $rootScope.$onRootScope rmapsEventConstants.principal.logout.success, () ->
    $log.debug 'LOGOUT:  Remove all HTTP cache entries'
    $http.defaults.cache.removeAll()

  return service
