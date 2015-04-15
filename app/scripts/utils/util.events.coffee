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


module.exports = ($timeout, $scope, mapCtrl, limits, $log, mapPath = 'map') ->
  #begin prep w dependencies

  _lastEvents =
    mouseover:null
    last: null

  _handleHover = (model, lObject, type, layerName) ->
    return if !layerName or !type
    if type == "marker" and layerName != 'addresses'
      mapCtrl.layerFormatter.MLS.setMarkerPriceOptions(model)
      lObject.setIcon(new L.divIcon(model.icon))

    #seems to be a google bug where mouse out is not always called
  _handleMouseout = (model, maybeCaller) =>
    if !model
      return
    model.isMousedOver = undefined

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
            handler[name](leafletEvent, leafletObject, model, modelName, layerName, 'marker')

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

          return if  _isParcelPoly(feature) and name != 'click' #NEED TO FIX ng-leaflet
          feature.coordinates = feature.geom_point_json.coordinates #makes resultsFormatter happy TODO: getCoords func ?
          if handler[name]?
            handler[name](event.originalEvent, undefined, feature, undefined, undefined, 'geojson')

  _eventHandler =
    ###
    interesting behavior for mouseover and mouseout:

    Chrome: If mouse is moved within a marker mouseover constantly fires even if it is the same marker

    ###
    mouseover: _.debounce (event, lObject, model, modelName, layerName, type, maybeCaller) ->
      if _isMarker(type) and model?.markerType? and
        (model.markerType == 'streetnum' or model.markerType == 'cluster') or
        _lastEvents.mouseover == model
          return
      _lastEvents.mouseover = model

      $log.debug "mouseover: type: #{type}, layerName: #{layerName}, modelName: #{modelName}"

      mapCtrl.openWindow(model)
      _lastHoveredModel = mapCtrl.lastHoveredModel
      mapCtrl.lastHoveredModel = model
      model.isMousedOver = true
      $timeout.cancel(mapCtrl.mouseoutDebounce)
      mapCtrl.mouseoutDebounce = null
      if _lastHoveredModel?.rm_property_id != model.rm_property_id
        _handleMouseout(_lastHoveredModel)

      _handleHover(model, lObject, type, layerName)

      if maybeCaller != 'results'
        $scope.formatters.results.mouseenter(null, model)

    , limits.options.throttle.eventPeriods.mouseout - 100

    mouseout: _.debounce (event, lObject, model, modelName, layerName, type, maybeCaller) ->
      if _isMarker(type) and model?.markerType? and
        (model.markerType == 'streetnum' or model.markerType == 'cluster')
          return

      _lastEvents.mouseover = null

      $log.debug "mouseout: type: #{type}, layerName: #{layerName}, modelName: #{modelName}"

      _handleMouseout(model, maybeCaller)
      _handleHover(model, lObject, type, layerName)
    , limits.options.throttle.eventPeriods.mouseout

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
