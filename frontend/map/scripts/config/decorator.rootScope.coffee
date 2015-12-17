app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.config(($provide) ->
  #recommended way of dealing with clean up of angular communication channels
  #http://stackoverflow.com/questions/11252780/whats-the-correct-way-to-communicate-between-controllers-in-angularjs
  $provide.decorator '$rootScope', ($delegate, $log) ->
    $log = $log.spawn("map:$rootScope")

    $delegate.debug = (obj) ->
      $log.debug(obj)

    Object.defineProperty $delegate.constructor::, '$onRootScope',
      value: (name, listener) ->
        unsubscribe = $delegate.$on(name, listener)
        @$on '$destroy', unsubscribe
        unsubscribe

      enumerable: false

    $delegate
)
