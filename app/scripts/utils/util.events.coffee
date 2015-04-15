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


module.exports = ($timeout, $scope, mapCtrl, limits, mapPath = 'map') ->
  #begin prep w dependencies

    #seems to be a google bug where mouse out is not always called
  _handleMouseout = (model) =>
    if !model
      return
    model.isMousedOver = undefined
    $timeout.cancel(mapCtrl.mouseoutDebounce)
    mapCtrl.mouseoutDebounce = null
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

  _hookMarkers = (handler) ->
    _markerEvents.forEach (name) ->
      eventName = 'leafletDirectiveMarker.' + name
      $scope.$onRootScope eventName, (event, args) ->
        _getArgs args, (leafletEvent, leafletObject, model, modelName, layerName) ->
          if handler[name]?
            handler[name](leafletEvent, leafletObject, model, modelName, layerName, 'marker')

  _hookGeojson = (handler) ->
    _geojsonEvents.forEach (name) ->
        eventName = 'leafletDirectiveMap.geojson' + name;
        $scope.$onRootScope eventName, (ngevent, feature, event) ->
          name = caseing.lower name
          return unless feature
          #ng-leaflet inconsistency
          return if Object.keys(feature).length == 7 and name != 'mouseout' #NEED TO FIX ng-leaflet
          if arguments.length < 3
            event = feature
            feature = event.feature

          if handler[name]?
            handler[name](event.originalEvent, undefined, feature, undefined, undefined, 'geojson')

  _eventHandler =
    mouseover: (event, lObject, model, modelName, layerName, type) ->
      if _isMarker(type) and model?.markerType? and (model.markerType == 'streetnum' or model.markerType == 'cluster') or layerName == 'addresses'
        return

      mapCtrl.openWindow(model)
      _lastHoveredModel = mapCtrl.lastHoveredModel
      mapCtrl.lastHoveredModel = model
      model.isMousedOver = true
      $timeout.cancel(mapCtrl.mouseoutDebounce)
      mapCtrl.mouseoutDebounce = null
      if _lastHoveredModel?.rm_property_id != model.rm_property_id
        _handleMouseout(_lastHoveredModel)

      $scope.formatters.results.mouseenter(null, model)

    mouseout: (event, lObject, model, modelName, layerName, type) ->
      if _isMarker(type) and model?.markerType? and (model.markerType == 'streetnum' or model.markerType == 'cluster')
        return
      $timeout.cancel(mapCtrl.mouseoutDebounce)
      mapCtrl.mouseoutDebounce = $timeout ->
        mapCtrl.closeWindow()
        _handleMouseout(model)
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
          unless mapCtrl.lastEvent == 'dblclick'
            $scope.formatters.results.showModel(model)
        , limits.clickDelayMilliSeconds

    dblclick: (event, lObject, model, modelName, layerName, type) ->
      mapCtrl.lastEvent = 'dblclick'
      {originalEvent} = event
      if originalEvent.stopPropagation then originalEvent.stopPropagation() else (originalEvent.cancelBubble=true)

      mapCtrl.saveProperty model, lObject
      $timeout =>
        #cleanup
        mapCtrl.lastEvent = undefined
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
