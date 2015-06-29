app = require '../app.coffee'
_eventThrottler = require '../utils/util.event-throttler.coffee'
_baseLayers = require '../utils/util.layers.base.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
_mapClassContainerName = 'angular-leaflet-map'

module.exports = app.factory 'rmapsBaseMap', ($log, $timeout, leafletData) ->
    class BaseMap
      initScopeSettings: (options, mapPath, baseLayers, mapEvents) ->
        settings =
          options: options

        disableWatchObj =
          doWatch:false
          isDeep: false
          individual:
            doWatch:false
            isDeep: false

        settings[mapPath] =
            isReady: true
            defaults:
              maxZoom: options.maxZoom
              minZoom: options.minZoom

            markersWatchOptions: _.cloneDeep disableWatchObj
            geojsonWatchOptions: _.cloneDeep disableWatchObj
            bounds: undefined
            center: options.json.center
            dragging: false,
            layers:
              baselayers: baseLayers

            events:
              map:
                enable: mapEvents,
                logic: 'emit'
            zoomBox: =>
              if @zoomBoxActive
                @zoomBoxActive = false
                @zoomBox.deactivate()
              else
                @zoomBoxActive = true
                @zoomBox.activate()

        angular.extend @scope, settings

      constructor: (@scope, options, redrawDebounceMilliSeconds, mapPath = 'map', mapId,  baseLayers = _baseLayers(), mapEvents = ['resize','moveend', 'zoomend'])->
        _throttler =  _eventThrottler($log, options)
        @initScopeSettings(options, mapPath, baseLayers, mapEvents)

        @hasRun = false
        @zoomChangedTimeMilli = new Date().getTime()
        @activeMarker = undefined
        self = @
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
            $log.debug "zoom: #{@scope.map?.center?.zoom}"

          $log.debug "redraw delay (small/false bad): #{_maybePingTime}"
          $log.debug "map event: #{leafletEvent.type}" if leafletEvent?.type?
          self.draw? 'idle'
        , redrawDebounceMilliSeconds

        leafletData.getDirectiveControls(mapId)
        .then (controls) =>
          @directiveControls = controls

        leafletData.getMap(mapId).then (map) =>
          @map =  map
          @map.whenReady  =>
            @scope[mapPath].isReady = true

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

          #due to the router hiding the map and timing the map needs to be resized
          #figuring out exactly when this is has been tricky (might try element .load)
          #however this might be easier making our own directive instead of factories
          $timeout =>
            @map.invalidateSize()#map's bounds is not valid until after this call
            leafletPreNamespace = 'leafletDirectiveMap.'
            mapEvents.forEach (eventName) =>
              eventName =  leafletPreNamespace + eventName
              return @scope.$on eventName, _maybeDraw

            _maybeDraw()

          , 200

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

        $log.info 'BaseMap: ' + @

#public fns
      isZoomIn: (newValue, oldValue) -> newValue > oldValue
