###globals angular,L,_###
app = require '../app.coffee'
_eventThrottler = require '../utils/util.event-throttler.coffee'

###
  This base map is primarily to deal with basic functionality of zoom and dragg issues.

  For example if only update markers if dragging has really changed. Also checking for zoom deltas (tooManyZoomChanges)
###
_mapClassContainerName = 'angular-leaflet-map'
_mapDrawEvents = ['resize','moveend', 'zoomend']

module.exports = app.factory 'rmapsBaseMapFactory', (
  $http
  nemSimpleLogger
  $timeout
  leafletData
  rmapsNgLeafletHelpersService
  rmapsUtilLayersBase
  rmapsNgLeafletEventGateService
) ->

  $log = nemSimpleLogger.spawn("map:baseFactory")

  class
    initScopeSettings: (options, mapPath, baseLayers, mapEvents) ->

      settings =
        options: options

      disableWatchObj =
        doWatch:false
        isDeep: false
        individual:
          doWatch: false
          isDeep: false

      settings[mapPath] =
          isReady: true
          defaults:
            maxZoom: options.maxZoom
            minZoom: options.minZoom
            zoomControl: false

          markersWatchOptions: _.cloneDeep disableWatchObj
          geojsonWatchOptions: _.cloneDeep disableWatchObj
          bounds: undefined
          center: options.json.center
          dragging: false
          layers:
            baselayers: {}

          events:
            map:
              enable: mapEvents,
              logic: 'emit'

          zoomBox: (force) =>
            if @zoomBoxActive or (force? && !force)
              @zoomBoxActive = false
              rmapsNgLeafletEventGateService.disableMapCommonEvents(@mapId)
              @zoomBox.deactivate()
            else
              if !force? or (force? && force)
                @zoomBoxActive = true
                rmapsNgLeafletEventGateService.enableMapCommonEvents(@mapId)
                @zoomBox.activate()

      if baseLayers?
        @scope[mapPath].layers.baselayers = baseLayers
      else
        rmapsUtilLayersBase.init()
        .then (data) =>
          @scope[mapPath].layers.baselayers = data
          return null

      angular.extend @scope, settings

    constructor: ({@scope, options, redrawDebounceMilliSeconds, mapPath, @mapId, baseLayers, mapEvents}) ->
      mapPath ?= 'map'
      mapEvents ?= _mapDrawEvents.concat ['click']

      _throttler =  _eventThrottler($log, options)
      @initScopeSettings(options, mapPath, baseLayers, mapEvents)

      @hasRun = false
      @zoomChangedTimeMilli = new Date().getTime()
      @zoomBox = L.control.zoomBox position: 'bottomleft'

      zoomBoxOrigActivate = @zoomBox.activate
      zoomBoxOrigDeactivate = @zoomBox.deactivate

      zoomBoxActivate = () =>
        rmapsNgLeafletEventGateService.disableMapCommonEvents(@mapId)
        zoomBoxOrigActivate.call(@zoomBox)

      zoomBoxDeactivate = () =>
        $timeout =>
          rmapsNgLeafletEventGateService.enableMapCommonEvents(@mapId)
        , 300
        zoomBoxOrigDeactivate.call(@zoomBox)

      @zoomBox.activate = zoomBoxActivate
      @zoomBox.deactivate = zoomBoxDeactivate


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
        _maybeDraw.cancel()
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

      leafletData.getDirectiveControls(@mapId)
      .then (controls) =>
        @directiveControls = controls

      leafletData.getMap(@mapId).then (map) =>
        @map =  map
        @map.whenReady  =>
          @scope[mapPath].isReady = true

        document.onkeydown = (e) =>
          e = e || window.event
          if e.keyCode == 27 #esc
            @scope[mapPath].zoomBox(false)
          if e.altKey && !e.metaKey && !e.shiftKey && !e.ctrlKey
            @scope[mapPath].zoomBox(true)

        #due to the router hiding the map and timing the map needs to be resized
        #figuring out exactly when this is has been tricky (might try element .load)
        #however this might be easier making our own directive instead of factories
        setTimeout =>
          @map.invalidateSize()#map's bounds is not valid until after this call
          leafletPreNamespace = "leafletDirectiveMap.#{rmapsNgLeafletHelpersService.events.getMapIdEventStr(@mapId)}"

          _mapDrawEvents.forEach (eventName) =>
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
        mapElement.addEventListener('moveend', _throttler.throttle_events, true)
        mapElement.addEventListener('mousemove', _throttler.throttle_events, true)

      # $log.info 'BaseMap: ' + @

    #public fns
    isZoomIn: (newValue, oldValue) -> newValue > oldValue

    fitBounds: (bounds) ->
      @map.fitBounds bounds
