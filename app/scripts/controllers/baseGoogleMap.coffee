#app = require '../app.coffee'

#module.exports = .controller('BaseGoogleMapCtrl'.ourNs(), ['$log','$http','$timeout', ($log,$http,$timeout) ->
#class BaseGoogleMapCtrl extends ns2.BaseObject
#  #all constructor arguments are for an instance (other stuff is singletons)
#  constructor: (@scope, @mapOptions,@urlProvider,@iconProvider,@zoomThresholdMill, @eventDispatcher) ->
#    google.maps.visualRefresh = true
#    @map = {}
#    @hasRun = false;
#    @zoomChangedTimeMilli = new Date().getTime()
#    @activeMarker = undefined
#
#    angular.extend $scope,
#      markers_url: '',
#      center: mapOptions.center
#      zoom: mapOptions.zoom,
#      dragging: false,
#      events:   #direct hook to google maps sdk events
#        tilesloaded: (map, eventName, originalEventArgs) =>
#          if !@hasRun
#            @map = map
#            @updateMarkers(@map,'ready')
#            @hasRun = true
#    ,
#      markers: [],
#      active_markers: [],
#      onMarkerClicked: (marker) =>
#        @onMarkerClicked(marker)
#
#    $scope.$watch 'zoom', (newValue, oldValue) =>
#      if (newValue == oldValue)
#        return
#      @eventDispatcher.on_event(@constructor.name,'zoom')
#      @updateMarkers(@map,'zoom') if !@scope.dragging and !@tooManyZoomChanges()
#
#    $scope.$watch 'dragging', (newValue, oldValue) =>
#      if (newValue == oldValue)
#        return
#      if(!newValue)   #if dragging is really over
#        @eventDispatcher.on_event(@constructor.name,'dragging')
#        @updateMarkers(@map,'dragging')
#    ,true
#
#  tooManyZoomChanges: =>
#    attemptTimeMilli = new Date().getTime()
#    delta = attemptTimeMilli - @zoomChangedTimeMilli
#    tooMany = @zoomThreshMilli >= delta
#    @zoomChangedTimeMilli = attemptTimeMilli if !tooMany
#    tooMany
#
#  isZoomIn:(newValue,oldValue) -> newValue > oldValue
#
#  # All to be derrived below
#  updateMarkers:(map,eventName) =>
#    throw new Error(MethodNotOverridenStr.format('updateMarkers'))
#  onMarkerClicked: (marker) =>
#    throw new Error(MethodNotOverridenStr.format('onMarkerClicked'))
#
#  $log.info @

#]