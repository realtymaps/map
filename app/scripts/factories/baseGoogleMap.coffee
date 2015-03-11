app = require '../app.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
module.exports = app.factory 'BaseGoogleMap'.ourNs(), [
  'Logger'.ourNs(), 'uiGmapIsReady', '$timeout',
  ($log, uiGmapIsReady, $timeout) ->
    class BaseGoogleMapCtrl
      last =
        time: new Date() # last time we let an event pass.
        x: -100 # last x position af the event that passed.
        y: -100 # last y position af the event that passed.

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
        uiGmapIsReady.promise().then (instances) =>
          @gMap = instances[0]?.map

        @map = {}
        @hasRun = false;
        @zoomChangedTimeMilli = new Date().getTime()
        @activeMarker = undefined
        self = @

        doThrottle = (event, distance, time) =>
          if event.type == 'mousewheel'
            return time < options.throttle.eventPeriods.mousewheel
          distance * time < options.throttle.space * options.throttle.eventPeriods.mousemove

        throttle_events = (event) ->
          now = new Date()
          distance = Math.sqrt(Math.pow(event.clientX - last.x, 2) + Math.pow(event.clientY - last.y, 2))
          time = now.getTime() - last.time.getTime()
          if doThrottle(event, distance, time)  #event arrived too soon or mouse moved too little or both
            $log.info 'event stopped'
            if event.stopPropagation # W3C/addEventListener()
              event.stopPropagation()
            else # Older IE.
              event.cancelBubble = true
          else
            $log.info 'event allowed: ' + now.getTime() if event.type == 'mousewheel'
            last.time = now
            last.x = event.clientX
            last.y = event.clientY
          return

        mapElement = _.first document.getElementsByClassName('angular-google-map-container')
        if mapElement? and mapElement.addEventListener?
          ###
           http://stackoverflow.com/questions/16645766/google-maps-api-v3-no-smooth-dragging
           register event handler that will throttle the events.
           "true" means we capture the event and so we get the event
           before Google Maps gets it. So if we cancel the event,
           Google Maps will never receive it.
          ###
          mapElement.addEventListener('mousemove', throttle_events, true)
#          mapElement.addEventListener('mousewheel', throttle_events, true) #ignoring as this seems to cause jerkyness

        angular.extend @scope,
          bounds: {}
          options: options
          center: options.json.center
          zoom: options.json.zoom,
          dragging: false,
          events:
            idle: ->
              $timeout ->
#                $log.debug 'idle'
                self.draw? 'idle' if !self.scope.dragging and !self.tooManyZoomChanges()
            zoom_changed: ->
              #early clearing of intense layers
              $timeout ->
                self.clearBurdenLayers()

        $log.info 'BaseGoogleMapCtrl: ' + @

      #check zoom deltas as to not query the backend until a view is solidified
      tooManyZoomChanges: =>
        attemptTimeMilli = new Date().getTime()
        delta = attemptTimeMilli - @zoomChangedTimeMilli
        tooMany = @zoomThreshMilli >= delta
        @zoomChangedTimeMilli = attemptTimeMilli if !tooMany
        tooMany

      isZoomIn: (newValue, oldValue) -> newValue > oldValue
]
