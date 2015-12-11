app = require '../app.coffee'
qs = require 'qs'

app.config(($httpProvider) ->
  $httpProvider.useApplyAsync(true)
)
.config(($provide) ->
  # attempting to create a cancelable $http on all its functions
  $provide.decorator '$http', ($delegate, $q, $cacheFactory) ->
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

      #TODO: could override promise with another to return data instead data.data (less annoying)

      # unless promise.success?
      #   promise.success = ->
      #     promise
      #   promise.error = (cb) ->
      #     promise.catch (err) ->
      #       cb(err)
      #     promise

      promise.cancel = ->
        canceler.resolve()

      promise.catch ->
        #if $q.all rejects a collection of promises then we can cancel the http
        promise.cancel()

      promise.finally ->
        #cleanup
        promise.cancel = angular.noop
        canceler = promise = null

      promise

    #pretty much straight copy paste from angular
    methods.forEach (method) ->
      $delegate[method] = (url, config) ->
        $delegate angular.extend config or {},
          method: method
          url: url

    dataMethods.forEach (method) ->
      $delegate[method] = (url, data, config) ->
        $delegate angular.extend config or {},
          method: method
          url: url
          data: data

    objectFields.forEach (name) ->
      $delegate[name] = http.root[name]

    $delegate
)
