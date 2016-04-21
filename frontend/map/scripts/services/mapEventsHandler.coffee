###globals _, L###
NgLeafletCenter = require('../../../../common/utils/util.geometries.coffee').NgLeafletCenter
app = require '../app.coffee'
events = require '../../../common/scripts/utils/events.coffee'

_isMarker = (type) ->
  type == 'marker'

app.service 'rmapsMapEventsHandlerService', (nemSimpleLogger, $timeout, rmapsMainOptions,
rmapsNgLeafletHelpersService, rmapsNgLeafletEventGateService, rmapsMapEventsLinkerService, rmapsLayerFormattersService,
rmapsPropertiesService, rmapsMapEventEnums, $log) ->

  _gate = rmapsNgLeafletEventGateService
  limits = rmapsMainOptions.map
  _markerEvents = rmapsNgLeafletHelpersService.events.markerEvents
  _geojsonEvents = rmapsNgLeafletHelpersService.events.geojsonEvents

  $log = $log.spawn("map:rmapsMapEventsHandlerService")

  (mapCtrl, mapPath = 'map', thisOriginator = 'map') ->
    $scope = mapCtrl.scope


    _lastEvents =
      mouseover:null
      last: null

    _handleHover = (model, lObject, type, layerName) ->
      return if !layerName or !type or !lObject
      if type == 'marker' and layerName != 'addresses' and model.markerType != 'note'
        rmapsLayerFormattersService.MLS.setMarkerPriceOptions(model)
      if type == 'geojson'
        opts = rmapsLayerFormattersService.Parcels.getStyle(model, layerName)
        lObject.setStyle(opts)

    _handleManualMarkerCluster = (model) ->
      if model.markerType == 'cluster'
        center = NgLeafletCenter(model)
        center.setZoom($scope[mapPath].center.zoom + 1)
        $scope[mapPath].center = center
        return true
      false

    _isParcelPoly = (feature) ->
      #crappy hack until leaflet fix
      len = Object.keys(feature).length
      len == 7


    _eventHandler =
      ###TODO:
      It would  be nice to make an open source event handling utility that automatically tracks
      what functions it has seen via some queueing mechanism. Thus it would simplify the below GTFO
      recursion logic. This is the case when pointing events to other eventhandlrs which are two-way.
      Thus in a two way event everything should be visited once.
      ###
      mouseover: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->

        # Grab some details about the original event for logging
        eventInfo = if event?.originalEvent then events.targetInfo(event.originalEvent) else 'mouseover - no originalEvent'

        if originator == thisOriginator and maybeCaller? # indicates recursion, bail
          # $log.debug '[IGNORED:recursion] ' + eventInfo
          return

        if _lastEvents.mouseover?.rm_property_id == model.rm_property_id # Detect whether this is firing from previous marker
          # $log.debug '[IGNORED:child] ' + eventInfo
          return

        if _isMarker(type) and (model?.markerType == 'streetnum' or model?.markerType == 'cluster') # Ignore these types of markers
          # $log.debug '[IGNORED:markertype] ' + eventInfo
          return

        $log.debug eventInfo

        # Show popup
        # not opening window until it is fixed from resutlsView, basic parcels have no info so skip
        if model.markerType != 'note' and !_gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.window.mouseover)
          mapCtrl.openWindow?(model)

        # Update model
        model.isMousedOver = true
        _lastEvents.mouseover = model

        # Update marker icon/style
        _handleHover model, lObject, type, layerName

      mouseout: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->

        # Grab some details about the original event for logging
        eventInfo = if event?.originalEvent then events.targetInfo(event.originalEvent) else 'mouseout - no originalEvent'

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

        # Close popup
        mapCtrl.closeWindow?()

        # Update model
        model.isMousedOver = false
        _lastEvents.mouseover = null

        # Update marker icon/style
        _handleHover model, lObject, type, layerName

      click: (event, lObject, model, modelName, layerName, type) ->
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.marker.click) and type is 'marker'
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.geojson.click) and type is 'geojson'
        $scope.$evalAsync ->
          #delay click interaction to see if a dblclick came in
          #if one did then we skip setting the click on resultFormatter to not show the details (cause our intention was to save)
          $timeout ->
            return if _handleManualMarkerCluster(model)
            if event.ctrlKey or event.metaKey
#              return mapCtrl.saveProperty(model, lObject)
              rmapsPropertiesService.pinUnpinProperty model
            unless _lastEvents.last == 'dblclick'
              $scope.formatters.results.showModel(model)
          , limits.clickDelayMilliSeconds

      dblclick: (event, lObject, model, modelName, layerName, type) ->
        _lastEvents.last = 'dblclick'
        {originalEvent} = event
        if originalEvent.stopPropagation then originalEvent.stopPropagation() else (originalEvent.cancelBubble=true)

        rmapsPropertiesService.pinUnpinProperty model
        $timeout ->
          #cleanup
          _lastEvents.last = undefined
        , limits.clickDelayMilliSeconds + 100
    #end prep w dependencies

    #do stuff / init
    obj = {}
    obj[mapPath] =
      events:
        markers:
          enable: _markerEvents
        geojson:
          enable: _geojsonEvents

    _.merge $scope,obj

    rmapsMapEventsLinkerService.hookMarkers(mapCtrl.mapId, _eventHandler, thisOriginator)
    rmapsMapEventsLinkerService.hookGeoJson(mapCtrl.mapId, _eventHandler, thisOriginator)

    rmapsMapEventsLinkerService.hookMap mapCtrl.mapId,
      click: (event) ->
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.map.click)

        geojson = (new L.Marker(event.latlng)).toGeoJSON()

        rmapsPropertiesService.getPropertyDetail(null, geom_point_json: geojson.geometry, 'all')
        .then (data) ->
          return if !data?.rm_property_id
          $scope.formatters.results.showModel(data)

    , thisOriginator, ['click']

    return _eventHandler
