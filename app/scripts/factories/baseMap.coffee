app = require '../app.coffee'
_eventThrottler = require('../utils/util.event-throttler.coffee')

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
_mapClassContainerName = 'angular-leaflet-map'


module.exports = app.factory 'BaseMap'.ourNs(), [
  'Logger'.ourNs(), 'uiGmapIsReady', '$timeout', 'leafletData',
  ($log, uiGmapIsReady, $timeout, leafletData) ->
    class BaseMap
      constructor: (@scope, options, redrawDebounceMilliSeconds, mapPath = 'map', mapId,  baseLayers = require('../utils/util.layers.base.coffee'), mapEvents = ['dragend', 'zoomend']) ->
        _throttler =  _eventThrottler($log, options)

        leafletData.getMap(mapId).then (map) =>
          @map =  map
          @zoomBox = L.control.zoomBox()
          map.addControl(@zoomBox)
          document.onkeydown = (e) =>
            e = e || window.event;
            if e.keyCode == 27 #esc
              self.zoomBoxActive = false
              @zoomBox.deactivate()
            if e.altKey
              self.zoomBoxActive = true
              @zoomBox.activate()

          $timeout =>
            @map.invalidateSize()
          , 1200
        leafletData.getDirectiveControls(mapId).then (controls) =>
          @directiveControls = controls

#pub vars
        @map = {}
        @hasRun = false
        @zoomChangedTimeMilli = new Date().getTime()
        @activeMarker = undefined
        self = @

#private fns
        _last = new Date()
        _now = null

        _pingPass = ->
          _now = new Date()
          diff = _now.getTime() - _last.getTime()
          if diff > redrawDebounceMilliSeconds
            _last = _now
            return diff
          false


        _maybeDraw = _.debounce (leafletDirectiveEvent, leaflet) =>
          #_pingPass ans debounce are all things to mimick map "idle" event
          leafletEvent = leaflet?.leafletEvent or undefined

          _maybePingTime = _pingPass()

          if leafletEvent?.type == 'zoomend'
            self.clearBurdenLayers()

          $log.debug "redraw delay (small/false bad): #{_maybePingTime}"
          $log.debug "map event: #{leafletEvent.type}" if leafletEvent?.type?
          self.draw? 'idle'
        , redrawDebounceMilliSeconds


        #init
        mapElement = _.first document.getElementsByClassName(_mapClassContainerName)
        if mapElement? and mapElement.addEventListener?
          ###
           http://stackoverflow.com/questions/16645766/google-maps-api-v3-no-smooth-dragging
           register event handler that will throttle the events.
           "true" means we capture the event and so we get the event
           before Google Maps gets it. So if we cancel the event,
           Google Maps will never receive it.
          ###
          mapElement.addEventListener('mousemove', _throttler.throttle_events, true)

        settings =
          options: options

        disableWatchObj =
          doWatch:false
          isDeep: false
          individual:
            doWatch:false
            isDeep: false

        settings[mapPath] =
            defaults:
              maxZoom: options.maxZoom
              minZoom: options.minZoom

            markersWatchOptions: _.cloneDeep disableWatchObj
            geojsonWatchOptions: _.cloneDeep disableWatchObj
            bounds: {}
            center: options.json.center
            dragging: false,
            layers:
              baselayers: baseLayers

            events:
              map:
                enable: mapEvents,
                logic: 'emit'
            zoomBox: ->
              if self.zoomBoxActive
                self.zoomBoxActive = false
                self.zoomBox.deactivate()
              else
                self.zoomBoxActive = true
                self.zoomBox.activate()

        angular.extend @scope, settings

        #using this instead of load since bad bounds seems to come out ng-leaflet
        _unWatchBounds = @scope.$watch 'map.bounds', (newValue, oldValue) ->
          if angular.equals(newValue, oldValue) or
            (newValue.northEast.lat == newValue.southWest.lat and newValue.northEast.lon == newValue.southWest.lon)
              return
          _unWatchBounds()
          _maybeDraw()

        leafletPreNamespace = 'leafletDirectiveMap.'
        mapEvents.forEach (eventName) =>
          eventName =  leafletPreNamespace + eventName
          return @scope.$on eventName, _maybeDraw

        $log.info 'BaseMap: ' + @

#public fns
      isZoomIn: (newValue, oldValue) -> newValue > oldValue
]
