_thisName = 'util.events'
Point = require('../../../common/utils/util.geometries.coffee').Point
caseing = require 'case'

_markerEvents= ['click', 'dblclick', 'mousedown', 'mouseover', 'mouseout']
#ng-leaflet inconsistency
_geojsonEvents = _markerEvents.map (e) -> caseing.capital e

_isMarker = (type) ->
  type == 'marker'

_getArgs = (args, cb) ->
  unless cb
    throw "#{_thisName}._getArgs: cb is undefined"
  {leafletEvent, leafletObject, model, modelName, layerName} = args
  return unless model
  cb(leafletEvent, leafletObject, model, modelName, layerName)

_lastHoveredFactory = (lObject, model, layerName, type) ->
  @destroy = =>
    @lObject = null
    @model = null
    @layerName =null
    @type = null

  @lObject = lObject
  @model = model
  @layerName =layerName
  @type = type
  @


module.exports = ($timeout, $scope, mapCtrl, limits, $log, mapPath = 'map', thisOriginator = 'map') ->
  #begin prep w dependencies


  _lastHovered = null

  _lastEvents =
    mouseover:null
    last: null

  _handleHover = (model, lObject, type, layerName, eventName) ->
    return if !layerName or !type
    if type == "marker" and layerName != 'addresses'
      mapCtrl.layerFormatter.MLS.setMarkerPriceOptions(model)
      lObject.setIcon(new L.divIcon(model.icon))
    if type == "geojson"
      if eventName == "mouseout"
        s = 's'
      opts = mapCtrl.layerFormatter.Parcels.getStyle(model, layerName)
      lObject.setStyle(opts)

    #seems to be a google bug where mouse out is not always called
  _handleMouseout = (model, maybeCaller) =>
    if !model
      return
    model.isMousedOver = false

    return if maybeCaller == 'results' #avoid recursion

    mapCtrl.closeWindow()
    $scope.formatters.results.mouseleave(null, model)

  _handleManualMarkerCluster = (model) ->
    if model.markerType == "cluster"
      copy = _.cloneDeep $scope[mapPath].center
      copy.lat= model.lat
      copy.lng = model.lng
      zoom = 14
      obj = _.extend new Point(copy), zoom: zoom
      $scope[mapPath].center = obj
      return true
    false

  _isParcelPoly = (feature) ->
    #crappy hack until leaflet fix
    len = Object.keys(feature).length
    len == 7

  _hookMarkers = (handler) ->
    _markerEvents.forEach (name) ->
      eventName = 'leafletDirectiveMarker.' + name
      $scope.$onRootScope eventName, (event, args) ->
        _getArgs args, (leafletEvent, leafletObject, model, modelName, layerName) ->
          if handler[name]?
            return if layerName == 'addresses'#IF the ignore list grows.. make an array
            handler[name](leafletEvent, leafletObject, model, modelName, layerName, 'marker', thisOriginator)

  _hookGeojson = (handler) ->
    _geojsonEvents.forEach (name) ->
        eventName = 'leafletDirectiveMap.geojson' + name;
        $scope.$onRootScope eventName, (ngevent, feature, event) ->
          name = caseing.lower name
          return unless feature
          #ng-leaflet inconsistency
          if arguments.length < 3
            event = feature
            feature = event.target.feature or {}

          # return if  _isParcelPoly(feature) and name != 'click' #NEED TO FIX ng-leaflet
          feature.coordinates = feature.geom_point_json.coordinates #makes resultsFormatter happy TODO: getCoords func ?
          lObject = event.layer
          layerName = lObject._layerName or if lObject.options.fillColor == "transparent" then "parcelBase" else "filterSummaryPoly"
          lObject._layerName = layerName
          if handler[name]?
            handler[name](event.originalEvent, lObject, feature, feature.rm_property_id, layerName, 'geojson', thisOriginator)

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

      # $log.debug "mouseover: type: #{type}, layerName: #{layerName}, modelName: #{modelName}"

      #not opening window until it is fixed from resutlsView, basic parcels have no info so skip
      mapCtrl.openWindow(model) if !maybeCaller

      model.isMousedOver = true

      #_lastHovered catches the edge case where a mouseout event was somehow missed (html or leaflet bug?)
      if _lastHovered? and _lastHovered?.model?.rm_property_id != model.rm_property_id
        _lastHovered.model.isMousedOver = false
        _handleMouseout(_lastHovered.model, maybeCaller)
        _handleHover(_lastHovered.model, _lastHovered.lObject, _lastHovered.type, _lastHovered.layerName, "mouseover-out")

      _handleHover(model, lObject, type, layerName, "mouseover")

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
      # $log.debug "mouseout: type: #{type}, layerName: #{layerName}, modelName: #{modelName}"

      _handleMouseout(model, maybeCaller)
      _handleHover(model, lObject, type, layerName, "mouseout")

    click: (event, lObject, model, modelName, layerName, type) ->
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
      lastEvents.last = 'dblclick'
      {originalEvent} = event
      if originalEvent.stopPropagation then originalEvent.stopPropagation() else (originalEvent.cancelBubble=true)

      mapCtrl.saveProperty model, lObject
      $timeout =>
        #cleanup
        lastEvents.last = undefined
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
  _hookMarkers(_eventHandler)
  _hookGeojson(_eventHandler)
  return _eventHandler
