###globals angular###
module = require '../module.coffee'
qs = require 'qs'

###globals angular, _###
module.config(($httpProvider) ->
  $httpProvider.useApplyAsync(true)
)
.config(($provide) ->
  # attempting to create a cancelable $http on all its functions
  $provide.decorator '$http', ($delegate, $q, $cacheFactory, rmapsPromiseDataProvider) ->
    flattenDataPromise = rmapsPromiseDataProvider.flattenDataPromise
    http = {}
    methods = ['get', 'delete', 'head', 'jsonp']
    dataMethods = ['post', 'put', 'patch']
    objectFields = ['defaults', 'pendingRequests']
    defaultCache = $cacheFactory.get('$http')

    allMethods = methods.concat(dataMethods)
    allMethods.forEach (m) ->
      http[m] = $delegate[m]
    http.root = $delegate

    $delegate = (config) ->
      canceler = $q.defer()

      angular.extend config, timeout: canceler.promise
      #eliminates the protocol error and allows the client library to handle the error easily
      #through catch and keeps the callstack traceable
      if !config? or !config.url?
        canceler.reject("invalid config #{JSON.stringify(config)}")
        return canceler.promise

      isPostCache = config.method == 'post' && config.cache == true

      if isPostCache
        elseClause = ->
          if _.isObject($delegate.defaults.cache) then $delegate.defaults.cache else defaultCache

        cache = if _.isObject(config?.cache) then config.cache else elseClause()
        url = config.url + qs.stringify config.data
        cachedResp = cache.get(url)

      if !cachedResp?
        promise = http.root(config)
        if isPostCache
          cache.put(url, promise)
      else
        promise = cachedResp

      promise.cancel = ->
        ###
          Edge case bug if the first request is canceled
          you do not want to resolve it. If you resolve then you
          might have cached a canceled request/ response. Which is nothing.
        ###
        canceler.reject('canceled')

      promise.catch ->
        #if $q.all rejects a collection of promises then we can cancel the http
        promise.cancel()

      promise.finally ->
        #cleanup
        promise.cancel = angular.noop
        canceler = promise = null

      promise

    getCache = (config) ->
      if angular.isObject(config?.cache)
        config.cache
      else if angular.isObject($delegate.defaults.cache)
        $delegate.defaults.cache
      else
        $cacheFactory.get('http')

    # if we are telling the cache not to be used make sure the old cache item is gone
    # this way when we re-cache we have update values
    maybeRemoveCacheItem = ({url, config}) ->
      cache = getCache(config)
      if config?.cache == false && cache?
        cache.remove(url)
      return

    #pretty much straight copy paste from angular
    methods.forEach (method) ->
      $delegate[method] = (url, config) ->
        maybeRemoveCacheItem {url, config}
        $delegate angular.extend config or {},
          method: method
          url: url

    dataMethods.forEach (method) ->
      $delegate[method] = (url, data, config) ->
        maybeRemoveCacheItem {url, config}
        $delegate angular.extend config or {},
          method: method
          url: url
          data: data

    (methods.concat dataMethods).forEach (method) ->
      $delegate[method + 'Data'] = () ->
        flattenDataPromise $delegate[method](arguments...)

    objectFields.forEach (name) ->
      $delegate[name] = http.root[name]

    $delegate
)
