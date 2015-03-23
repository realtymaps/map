app = require '../app.coffee'


app.factory 'PromiseThrottler'.ourNs(), [
  'Logger'.ourNs(), '$timeout', '$q', '$rootScope', 'events'.ourNs(), 'MainOptions'.ourNs(), 'uiGmapPropMap',
  ($log, $timeout, $q, $rootScope, Events, MainOptions, PropMap) ->

    defaultName = 'PromiseThrottler'
    defaultNameIndex = 0
    ###
      Simple Class to Keep Track of its own promises to debounce
    ###
    (name) ->
      self = this
      unless name
        name = "#{defaultName}-#{defaultNameIndex}"
        defaultNameIndex += 1
      this.name = name

      promiseHash = new PropMap()
      promisesIndex = 0

      cancelAll = ->
        if promiseHash.length
          promiseHash.each (cancelHandler) ->
            cancelHandler()
      ###
        A promise has ben executed;
        cache it, if it is still there later.. cancel it.

        If it finishes gracefully or is forced (canceled)
        it will remove itself from the cache.
      ###
      @invokePromise = (cancelablePromise, options) =>
        deferred = $q.defer()
        nonCancelpromise = deferred.promise

        cancelAll()

        return unless options
        myId = promisesIndex += 1

        if !cancelablePromise?
          deferred.resolve()
          return nonCancelpromise

        cancelablePromise.then (data) ->
          deferred.resolve(data.data) if data?
        .finally =>
          promiseHash.remove(@name + myId)

        promiseHash.put(@name + myId, () ->
          ### these alerts won't be sent in the first place, now
          # prevent alerts from the canceled $http call
          if options.http?
            opts =
              id: "0-#{options.http.route or name}"
              quietMillis: MainOptions.alert.cancelQuietMillis

            $rootScope.$emit Events.alert.prevent, opts
          ###

          # do the cancel
          cancelablePromise.cancel()
        )

        deferred.promise #return a regular promise

      @reset = cancelAll

      @
]
