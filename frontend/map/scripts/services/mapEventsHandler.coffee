NgLeafletCenter = require('../../../../common/utils/util.geometries.coffee').NgLeafletCenter
caseing = require 'case'
app = require '../app.coffee'

_isMarker = (type) ->
  type == 'marker'

_lastHoveredFactory = (lObject, model, layerName, type) ->
  @destroy = =>
    @lObject = null
    @model = null
    @layerName = null
    @type = null

  @lObject = lObject
  @model = model
  @layerName =layerName
  @type = type
  @

app.service 'rmapsMapEventsHandlerService', (nemSimpleLogger, $timeout, rmapsMainOptions,
rmapsNgLeafletHelpers, rmapsNgLeafletEventGate, rmapsMapEventsLinkerService, rmapsLayerFormatters,
rmapsPropertiesService, rmapsMapEventEnums) ->

  _gate = rmapsNgLeafletEventGate
  limits = rmapsMainOptions.map
  _markerEvents = rmapsNgLeafletHelpers.events.markerEvents
  _geojsonEvents = rmapsNgLeafletHelpers.events.geojsonEvents

  $log = nemSimpleLogger.spawn("map:rmapsMapEventsHandlerService")

  (mapCtrl, mapPath = 'map', thisOriginator = 'map') ->
    $scope = mapCtrl.scope

    _lastHovered = null

    _lastEvents =
      mouseover:null
      last: null

    _handleHover = (model, lObject, type, layerName, eventName) ->
      return if !layerName or !type or !lObject
      if type == 'marker' and layerName != 'addresses' and model.markerType != 'note'
        rmapsLayerFormatters.MLS.setMarkerPriceOptions(model)
        lObject.setIcon(new L.divIcon(model.icon))
      if type == 'geojson'
        if eventName == 'mouseout'
          s = 's'
        opts = rmapsLayerFormatters.Parcels.getStyle(model, layerName)
        lObject.setStyle(opts)

      #seems to be a google bug where mouse out is not always called
    _handleMouseout = (model, maybeCaller) ->
      if !model
        return
      model.isMousedOver = false

      return if maybeCaller == 'results' #avoid recursion

      mapCtrl.closeWindow() if mapCtrl.closeWindow?
      $scope.formatters.results.mouseleave(null, model)

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
        if _isMarker(type) and model?.markerType? and
            (model.markerType == 'streetnum' or model.markerType == 'cluster') or
            _lastEvents.mouseover?.rm_property_id == model.rm_property_id or
            (originator == thisOriginator and maybeCaller?) #this has been called here b4 originally
          return
        _lastEvents.mouseover = model
        _lastEvents.mouseout = null

        # $log.debug mouseover: type: #{type}, layerName: #{layerName}, modelName: #{modelName}

        #not opening window until it is fixed from resutlsView, basic parcels have no info so skip
        if model.markerType != 'note'
          return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.window.mouseover)
          mapCtrl.openWindow(model, lObject) if !maybeCaller && mapCtrl.openWindow?

        model.isMousedOver = true

        #_lastHovered catches the edge case where a mouseout event was somehow missed (html or leaflet bug?)
        if _lastHovered? and _lastHovered?.model?.rm_property_id != model.rm_property_id
          _lastHovered.model.isMousedOver = false
          _handleMouseout(_lastHovered.model, maybeCaller)
          _handleHover(_lastHovered.model, _lastHovered.lObject, _lastHovered.type, _lastHovered.layerName, 'mouseover-out')

        _handleHover(model, lObject, type, layerName, 'mouseover')

        _lastHovered = new _lastHoveredFactory(lObject, model, layerName, type)

        if maybeCaller != 'results'
          $scope.formatters.results.mouseenter(null, model)

      mouseout: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
        if _isMarker(type) and model?.markerType? and
            (model.markerType == 'streetnum' or model.markerType == 'cluster')  or
            # _lastEvents.mouseout?.rm_property_id == model.rm_property_id or
            (originator == thisOriginator and maybeCaller?) #this has been called here b4 originally
          return

        _lastEvents.mouseout = model
        _lastEvents.mouseover = null

        _handleMouseout(model, maybeCaller)
        _handleHover(model, lObject, type, layerName, 'mouseout')

      click: (event, lObject, model, modelName, layerName, type) ->
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.marker.click) and type is 'marker'
        return if _gate.isDisabledEvent(mapCtrl.mapId, rmapsMapEventEnums.geojson.click) and type is 'geojson'
        $scope.$evalAsync ->
          #delay click interaction to see if a dblclick came in
          #if one did then we skip setting the click on resultFormatter to not show the details (cause our intention was to save)
          {originalEvent} = event if event?
          $timeout ->
            return if _handleManualMarkerCluster(model)
            if event.ctrlKey or event.metaKey
              return mapCtrl.saveProperty(model, lObject)
            unless _lastEvents.last == 'dblclick'
              $scope.formatters.results.showModel(model)
          , limits.clickDelayMilliSeconds

      dblclick: (event, lObject, model, modelName, layerName, type) ->
        _lastEvents.last = 'dblclick'
        {originalEvent} = event
        if originalEvent.stopPropagation then originalEvent.stopPropagation() else (originalEvent.cancelBubble=true)

        mapCtrl.saveProperty model, lObject
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

        rmapsPropertiesService.getPropertyDetail(null, geom_point_json: JSON.stringify(geojson.geometry), 'all')
        .then (data) ->
          return if !data?.rm_property_id
          $scope.formatters.results.showModel(data)

    , thisOriginator, ['click']

    return _eventHandler
