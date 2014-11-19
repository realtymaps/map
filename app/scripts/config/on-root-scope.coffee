app = require '../app.coffee'
#recommended way of dealing with clean up of angular communication channels
#http://stackoverflow.com/questions/11252780/whats-the-correct-way-to-communicate-between-controllers-in-angularjs
app.config [ "$provide", ($provide) ->
  $provide.decorator "$rootScope", [ "$delegate", ($delegate) ->
    Object.defineProperty $delegate.constructor::, "$onRootScope",
      value: (name, listener) ->
        unsubscribe = $delegate.$on(name, listener)
        @$on "$destroy", unsubscribe
        unsubscribe

      enumerable: false

    return $delegate
  ]
]