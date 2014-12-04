app = require '../app.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
module.exports = app.factory 'BaseGoogleMap'.ourNs(), ['uiGmapLogger','$http','$timeout', ($log) ->
    class BaseGoogleMapCtrl extends BaseObject
      #all constructor arguments are for an instance (other stuff is singletons)
      constructor: (@scope, options, @zoomThresholdMill) ->
        @map = {}
        @hasRun = false;
        @zoomChangedTimeMilli = new Date().getTime()
        @activeMarker = undefined

        angular.extend @scope,
          bounds: {}
          options: options
          center: options.json.center
          zoom: options.json.zoom,
          dragging: false,
          events:   #direct hook to google maps sdk events
            tilesloaded: (map, eventName, originalEventArgs) =>
              if !@hasRun
                @map = map
                @hasRun = true

        unBindWatchBounds = @scope.$watch 'map.bounds', (newValue, oldValue) =>
          return if (newValue == oldValue)
          @draw? 'ready'
        , true

        @scope.$watch 'zoom', (newValue, oldValue) =>
          return if (newValue == oldValue)
          @draw? 'zoom' if !@scope.dragging and !@tooManyZoomChanges()

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
