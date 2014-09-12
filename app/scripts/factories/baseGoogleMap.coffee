app = require '../app.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
module.exports = app.factory 'BaseGoogleMap'.ourNs(), ['Logger'.ns(),'$http','$timeout', ($log) ->
    class BaseGoogleMapCtrl extends BaseObject
      #all constructor arguments are for an instance (other stuff is singletons)
      constructor: (@scope, @mapOptions,@urlProvider,@iconProvider,@zoomThresholdMill, @eventDispatcher) ->
        @map = {}
        @hasRun = false;
        @zoomChangedTimeMilli = new Date().getTime()
        @activeMarker = undefined

        angular.extend $scope,
          markers_url: '',
          center: mapOptions.center
          zoom: mapOptions.zoom,
          dragging: false,
          events:   #direct hook to google maps sdk events
            tilesloaded: (map, eventName, originalEventArgs) =>
              if !@hasRun
                @map = map
                @updateMarkers(@map,'ready')
                @hasRun = true
        ,
          markers: [],
          active_markers: [],
          onMarkerClicked: (marker) =>
            @onMarkerClicked(marker)

        $scope.$watch 'zoom', (newValue, oldValue) =>
          if (newValue == oldValue)
            return
          @eventDispatcher.on_event(@constructor.name,'zoom')
          @updateMarkers(@map,'zoom') if !@scope.dragging and !@tooManyZoomChanges()

        $scope.$watch 'dragging', (newValue, oldValue) =>
          if (newValue == oldValue)
            return
          if(!newValue)   #if dragging is really over
            @eventDispatcher.on_event(@constructor.name,'dragging')
            @updateMarkers(@map,'dragging')
        ,true

      #check zoom deltas as to not query the backend until a view is solidified
      tooManyZoomChanges: =>
        attemptTimeMilli = new Date().getTime()
        delta = attemptTimeMilli - @zoomChangedTimeMilli
        tooMany = @zoomThreshMilli >= delta
        @zoomChangedTimeMilli = attemptTimeMilli if !tooMany
        tooMany

      isZoomIn:(newValue,oldValue) -> newValue > oldValue

      # All to be derrived below
      updateMarkers:(map,eventName) =>
        throw new Error(MethodNotOverridenStr.format('updateMarkers'))
      onMarkerClicked: (marker) =>
        throw new Error(MethodNotOverridenStr.format('onMarkerClicked'))

      $log.info @

]
