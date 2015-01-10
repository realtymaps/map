app = require '../app.coffee'

app.config([ '$provide', ($provide) ->
  #recommended way of dealing with clean up of angular communication channels
  #http://stackoverflow.com/questions/11252780/whats-the-correct-way-to-communicate-between-controllers-in-angularjs
  $provide.decorator '$rootScope', [ '$delegate', ($delegate) ->
    Object.defineProperty $delegate.constructor::, '$onRootScope',
      value: (name, listener) ->
        unsubscribe = $delegate.$on(name, listener)
        @$on '$destroy', unsubscribe
        unsubscribe

      enumerable: false

    $delegate
]])
.config([ '$provide', '$qProvider', ($provide, $q) ->
  # attempting to create a cancelable $http on all its functions
  $provide.decorator '$http', [ '$delegate', ($delegate) ->
    http = {}
    methods = ['get', 'delete', 'head', 'jsonp']
    dataMethods = ['post', 'put', 'patch']
    allMethods = methods.concat(dataMethods)
    allMethods.forEach (m) ->
      http[m] = $delegate[m]
    http.root = $delegate

    $delegate = (requestConfig) ->
      canceller = $q.defer()
      angular.extend requestConfig, timeout: canceller.promise
      promise = http.root(requestConfig)
      #TODO: could override promise with another to return data instead data.data (less annoying)

      promise.cancel = ->
        canceller.resolve()

      promise.reject ->
        #if $q.all rejects a collection of promises then we can cancel the http
        promise.cancel()

      promise.finally ->
        #cleanup
        promise.abort = angular.noop
        canceller = promise = http = null

    allMethods.forEach (m) ->
      $delegate[m] = http[m]

    return $delegate
]])
