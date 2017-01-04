mod = require '../module.coffee'
_ = require 'lodash'

mod.config ($provide) ->
  ###
  using decorator until this is resolved
  https://github.com/mattlewis92/angular-bluebird-promises/issues/15

  Purpose: To decorate $q to have similar signatures / interfaces to bluebird promises. Only add minimal functionality
           as angular-bluebird-promises will be used in the future once the above issue is resolved.

  OR
  NOTE:
  # maybe later on angular-extend-promises
  # their .each is buggy and does not pass bluebird specs
  # lastly the module is difficult to import '../tmp/lodash' must be replaced everywhere
  # see: https://bitbucket.org/lsystems/angular-extend-promises/issues/3/how-do-you-import-this-library-via-commnjs
  # require('angular-extend-promises/angular-extend-promises-without-lodash.js')
  ###
  $provide.decorator '$q', ($delegate, $rootScope, $log) ->
    $log = $log.spawn('$q')

    _promise = ($q, deferCb) ->
      d = $q.defer()
      deferCb(d)
      d.promise

    if !$delegate.resolve
      $delegate.resolve = $delegate.when

    if !$delegate.reject
      $delegate.reject = (reason) ->
        _promise @, (d) ->
          d.reject(reason)

    if !$delegate.delay #NOTE DO NOT USE ME IN SPECS angular hates setTmeout
      $delegate.delay = (millSec, toResolve) ->
        _promise @, (d) ->
          setTimeout () -> #NOTE CAN't use $timeout (circular dependency to $q)
            d.resolve(toResolve)
          , millSec


    if !$delegate.each?
      $delegate.each = (collection, cb) ->
        if !collection?.length
          return $delegate.resolve(collection)

        promises = [$delegate.resolve()]
        d = $delegate.defer()

        #to keep k, v integrity as _.sortBy removes keys
        collection = _.map collection, (v,k) -> {v,k}
        #sortBy keys
        invertedVals = _.sortBy(collection, (v, k) -> -1 * k)

        doNext = (index) ->
          if invertedVals.length
            obj = invertedVals.pop()
            $log.debug -> "doNext"
            $log.debug -> obj
            return next(obj, index)

          return $delegate.all(promises).then(d.resolve, d.reject)


        next = (obj, index) ->
          p = promises[index].then ->
            $log.debug -> "should resolve"
            $log.debug -> obj.v
            obj.v
          .then (v) ->
            $log.debug -> "resolved: #{v}"
            cb(v,obj.k, collection.length) #this could be a promise so call it prior to next step
          .then (res) ->
            doNext(index++)
            res

          promises.push(p)
          return p

        doNext(0)
        return d.promise


    if !$delegate.map?
      $delegate.map = (collection, cb) ->
        if !collection?.length
          return $delegate.resolve(collection)

        promises = for v,i in collection
          $delegate.when(v)
          .then (v) ->
            cb(v, i, collection.length)

        return $delegate.all(promises)

    # $log.debug -> '$q'
    # $log.debug -> $delegate
    $delegate
