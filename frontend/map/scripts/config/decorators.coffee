app = require '../app.coffee'

app.config(($provide) ->
  #recommended way of dealing with clean up of angular communication channels
  #http://stackoverflow.com/questions/11252780/whats-the-correct-way-to-communicate-between-controllers-in-angularjs
  $provide.decorator '$rootScope', ($delegate) ->
    Object.defineProperty $delegate.constructor::, '$onRootScope',
      value: (name, listener) ->
        unsubscribe = $delegate.$on(name, listener)
        @$on '$destroy', unsubscribe
        unsubscribe

      enumerable: false

    $delegate
)
.config(($httpProvider) ->
    $httpProvider.useApplyAsync(true)
)
.config(($provide) ->
  # attempting to create a cancelable $http on all its functions
  $provide.decorator '$http', ($delegate, $q) ->
    http = {}
    methods = ['get', 'delete', 'head', 'jsonp']
    dataMethods = ['post', 'put', 'patch']
    objectFields = ['defaults', 'pendingRequests']

    allMethods = methods.concat(dataMethods)
    allMethods.forEach (m) ->
      http[m] = $delegate[m]
    http.root = $delegate

    $delegate = (requestConfig) ->
      canceller = $q.defer()
      angular.extend requestConfig, timeout: canceller.promise
      #eliminates the protocol error and allows the client library to handle the error easily
      #through catch and keeps the callstack traceable
      if !requestConfig? or !requestConfig.url?
        canceller.reject("invalid requestConfig #{JSON.stringify(requestConfig)}")
        return canceller.promise
      promise = http.root(requestConfig)
      #TODO: could override promise with another to return data instead data.data (less annoying)

      promise.cancel = ->
        canceller.resolve()

      promise.catch ->
        #if $q.all rejects a collection of promises then we can cancel the http
        promise.cancel()

      promise.finally ->
        #cleanup
        promise.cancel = angular.noop
        canceller = promise = null

      promise

    #pretty much straight copy paste from angular
    methods.forEach (name) ->
      $delegate[name] = (url, config) ->
        $delegate angular.extend config or {},
          method: name
          url: url

    dataMethods.forEach (name) ->
      $delegate[name] = (url, data, config) ->
        $delegate angular.extend config or {},
          method: name
          url: url
          data: data

    objectFields.forEach (name) ->
      $delegate[name] = http.root[name]

    $delegate
)