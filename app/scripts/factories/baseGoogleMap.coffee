app = require '../app.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
module.exports = app.factory 'BaseGoogleMap'.ourNs(), [
  'uiGmapLogger', 'uiGmapIsReady', '$timeout',
  ($log, uiGmapIsReady, $timeout) ->
    $log.currentLevel = $log.LEVELS.warn
    class BaseGoogleMapCtrl extends BaseObject
      #all constructor arguments are for an instance (other stuff is singletons)
      constructor: (@scope, options, @zoomThresholdMill) ->
        @map = {}
        @hasRun = false;
        @zoomChangedTimeMilli = new Date().getTime()
        @activeMarker = undefined
        self = @
        angular.extend @scope,
          bounds: {}
          options: options
          center: options.json.center
          zoom: options.json.zoom,
          dragging: false,
          events:
            idle: ->
              $timeout ->
                self.draw? 'idle' if !self.scope.dragging and !self.tooManyZoomChanges()

        $log.info 'BaseGoogleMapCtrl: ' + @

      #check zoom deltas as to not query the backend until a view is solidified
      tooManyZoomChanges: =>
        attemptTimeMilli = new Date().getTime()
        delta = attemptTimeMilli - @zoomChangedTimeMilli
        tooMany = @zoomThreshMilli >= delta
        @zoomChangedTimeMilli = attemptTimeMilli if !tooMany
        tooMany

      isZoomIn:(newValue,oldValue) -> newValue > oldValue

]
