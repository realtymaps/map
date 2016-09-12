###globals _, L###
app = require '../app.coffee'
eventUtil = require '../../../common/scripts/utils/events.coffee'

_isMarker = (type) ->
  type == 'marker'

app.service 'rmapsEventsHandlerService', (
$timeout
rmapsMainOptions
rmapsNgLeafletHelpersService
rmapsNgLeafletEventGateService
rmapsEventsLinkerService
rmapsLayerFormattersService
rmapsPropertiesService
rmapsMapEventEnums
rmapsHoverQueue
rmapsZoomLevelService
rmapsPopupLoaderService
rmapsEventsHandlerInternalsService
$log) ->
  internals = rmapsEventsHandlerInternalsService
  _gate = rmapsNgLeafletEventGateService

  _hoverQueue = new rmapsHoverQueue()

  $log = $log.spawn("map:rmapsEventsHandlerService")

  {limits, events, inject} = internals

  (mapCtrl, mapPath = 'map', thisOriginator = 'map') ->

    $scope = mapCtrl.scope
    _hoverQueue = new rmapsHoverQueue()

    {
      handleManualMarkerCluster, getPropertyDetail, openWindow, closeWindow
    } = inject({mapCtrl, mapPath, thisOriginator})

    _eventHandler =
      ###TODO:
      It would  be nice to make an open source event handling utility that automatically tracks
      what functions it has seen via some queueing mechanism. Thus it would simplify the below GTFO
      recursion logic. This is the case when pointing events to other eventhandlrs which are two-way.
      Thus in a two way event everything should be visited once.
      ###
      mouseover: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
        #toBack
        #https://github.com/Leaflet/Leaflet/issues/3708
        #http://jsfiddle.net/kytqgpjo/2/
        if lObject?.bringToBack?
          lObject.bringToBack()
        else
          e = lObject._icon.parentNode
          e.insertBefore(lObject._icon, e.firstChild)
        # Grab some details about the original event for logging
        eventInfo = if event?.originalEvent then eventUtil.targetInfo(event.originalEvent) else 'mouseover - no originalEvent'

        if originator == thisOriginator and maybeCaller? # indicates recursion, bail
          # $log.debug '[IGNORED:recursion] ' + eventInfo
          return

        # Ignore when this is firing from previous marker
        if (events.last.mouseover?.lat? && events.last.mouseover?.lng? && (events.last.mouseover.lat == model.coordinates[1]) && (events.last.mouseover.lng == model.coordinates[0]))
          # $log.debug '[IGNORED:child] ' + eventInfo
          return

        # Ignore these types of markers
        if _isMarker(type) and (model?.markerType == 'streetnum' or model?.markerType == 'cluster')
          # $log.debug '[IGNORED:markertype] ' + eventInfo
          return

        if event?.originalEvent?.relatedTarget?.className?.slice? # Detect whether this is firing on a child element
          # $log.debug '[IGNORED:child] ' + eventInfo
          return

        $log.debug eventInfo

        # Show popup
        # not opening window until it is fixed from resutlsView, basic parcels have no info so skip
        # if model.markerType != 'note' and !_gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.window.mouseover)
        #   _openWindow(model)

        # Update model
        model.isMousedOver = true
        events.last.mouseover = model

        # Update marker icon/style
        _hoverQueue.enqueue {model, lObject, type, layerName}

      mouseout: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->

        # Grab some details about the original event for logging
        eventInfo = if event?.originalEvent then eventUtil.targetInfo(event.originalEvent) else 'mouseout - no originalEvent'

        if originator == thisOriginator and maybeCaller? # indicates recursion, bail
          # $log.debug '[IGNORED:recursion] ' + eventInfo
          return

        if event?.originalEvent?.relatedTarget?.className?.slice? # Detect whether this is firing on a child element
          # $log.debug '[IGNORED:child] ' + eventInfo
          return

        if _isMarker(type) and (model?.markerType == 'streetnum' or model?.markerType == 'cluster') # Ignore these types of markers
          # $log.debug '[IGNORED:markertype] ' + eventInfo
          return

        $log.debug eventInfo

        # Update model
        model.isMousedOver = false
        events.last.mouseover = null

        # Update marker icon/style
        _hoverQueue.dequeue()

      click: (event, lObject, model, modelName, layerName, type) ->
        eventInfo = if event?.originalEvent then eventUtil.targetInfo(event.originalEvent) else 'mouseout - no originalEvent'

        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.marker.click) and type is 'marker'
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.geojson.click) and type is 'geojson'

        $log.debug eventInfo

        $scope.$evalAsync ->
          #delay click interaction to see if a dblclick came in
          #if one did then we skip setting the click on resultFormatter to not show the details (cause our intention was to save)
          setTimeout ->
            return if handleManualMarkerCluster(model)
            if event.ctrlKey or event.metaKey
              # return mapCtrl.saveProperty(model, lObject)
              rmapsPropertiesService.pinUnpinProperty model
            if events.last.last != 'dblclick'
              # if model.markerType != 'price-group'
              #   $scope.formatters.results.showModel(model)
              if model.markerType != 'note' and !_gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.window.mouseover)
                openWindow(model)

          , limits.clickDelayMilliSeconds - 100

      dblclick: (event, lObject, model, modelName, layerName) ->
        events.last.last = 'dblclick'
        {originalEvent} = event
        if originalEvent.stopPropagation then originalEvent.stopPropagation() else (originalEvent.cancelBubble=true)

        rmapsPropertiesService.pinUnpinProperty model
        $timeout ->
          #cleanup
          events.last.last = undefined
        , limits.clickDelayMilliSeconds + 100
    #end prep w dependencies

    #do stuff / init
    obj = {}
    obj[mapPath] =
      events:
        markers:
          enable: events.marker
        geojson:
          enable: events.geojson

    _.merge $scope,obj

    rmapsEventsLinkerService.hookMarkers(mapCtrl.mapId, _eventHandler, thisOriginator)
    rmapsEventsLinkerService.hookGeoJson(mapCtrl.mapId, _eventHandler, thisOriginator)

    rmapsEventsLinkerService.hookMap mapCtrl.mapId,
      click: (event) ->
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.map.click)
        $log.debug -> event

        popupWasClosed = closeWindow()

        if !popupWasClosed && rmapsZoomLevelService.isParcel($scope.map.center.zoom)
          geojson = (new L.Marker(event.latlng)).toGeoJSON()
          getPropertyDetail(geometry_center: geojson.geometry)
          $log.debug 'Showing property details if a parcel was clicked'

          ### Alternate code to show infowindow instead of property details
          rmapsPropertiesService.getPropertyDetail(null, geometry_center: geojson.geometry, 'filter')
          .then (data) ->
            model = data.mls?[0] || data.county?[0]
            return if !model

            model.coordinates ?= model.geometry_center?.coordinates
            model.markerType = 'price'

            setTimeout ->
              if events.last.last != 'dblclick'
                openWindow(model)
            , limits.clickDelayMilliSeconds - 100
          ###

      moveend: (event) ->
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.map.click)
        closeWindow()

    , thisOriginator, ['click', 'moveend']

    return _eventHandler
