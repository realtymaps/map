app = require '../app.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
module.exports = app.factory 'BaseGoogleMap'.ourNs(), [
  'uiGmapLogger', 'uiGmapIsReady', '$timeout',
  ($log, uiGmapIsReady, $timeout) ->
    class BaseGoogleMapCtrl extends BaseObject
      #all constructor arguments are for an instance (other stuff is singletons)
      @getDragZoomOptions = ->
        visualEnabled: true,
        visualPosition: google.maps.ControlPosition.LEFT,
        visualPositionOffset: new google.maps.Size(25, 425),
        visualPositionIndex: null,
        #TODO: change this image, DAN?
        visualSprite: "http://maps.gstatic.com/mapfiles/ftr/controls/dragzoom_btn.png",
        visualSize: new google.maps.Size(20, 20),
        visualTips:
          off: "Turn on",
          on: "Turn off"

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
