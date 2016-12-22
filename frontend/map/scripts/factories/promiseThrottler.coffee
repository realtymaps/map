_ = require 'lodash'
app = require '../app.coffee'

app.factory 'rmapsPromiseThrottlerFactory', ($log, $timeout, $q) ->

  defaultName = 'PromiseThrottler'
  defaultNameIndex = 0
  ###
    Simple Class to Keep Track of its own promises to debounce
  ###
  (name) ->
    unless name
      name = "#{defaultName}-#{defaultNameIndex}"
      defaultNameIndex += 1
    this.name = name

    promiseHash = {}
    promisesIndex = 0

    cancelAll = () ->
      if _.keys(promiseHash).length
        _.each promiseHash, (promise) ->
          promise.cancel()
    ###
      A promise has ben executed;
      cache it, if it is still there later.. cancel it.

      The cache is short lived and evey child promiseis responsible for cleaning up itself
      and removing itself from the cache. Removal upon resolve (graceful) or ugly (cance/reject).
    ###
    invokePromise = (cancelablePromise, options) =>
      deferred = $q.defer()
      nonCancelpromise = deferred.promise

      cancelAll()

      return unless options
      promisesIndex += 1

      if !cancelablePromise?
        deferred.resolve()
        return nonCancelpromise

      cancelablePromise.then (data) ->
        deferred.resolve(data.data) if data?
      .catch (error) ->
        deferred.reject(error)
      .finally () =>
        delete promiseHash[@name + promisesIndex]

      promiseHash[@name + promisesIndex] = cancelablePromise

      deferred.promise #return a regular promise

    invokePromise: invokePromise
    reset: cancelAll
    cancelAll: cancelAll
