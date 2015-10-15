mod = require '../module.coffee'

mod.config ($provide) ->
  ###
  using decorator until this is resolved
  https://github.com/mattlewis92/angular-bluebird-promises/issues/15

  Purpose: To decorate $q to have similar signatures / interfaces to bluebird promises. Only add minimal functionality
           as angular-bluebird-promises will be used in the future once the above issue is resolved.
  ###
  $provide.decorator '$q', ($delegate) ->
    _promise = ($q, deferCb) ->
      d = $q.defer()
      deferCb(d)
      d.promise

    $delegate.resolve = (val) ->
      _promise @, (d) ->
        d.resolve(val)

    $delegate.reject = (reason) ->
      _promise @, (d) ->
        d.reject(reason)

    $delegate
