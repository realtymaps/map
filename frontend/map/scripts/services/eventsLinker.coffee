app = require '../app.coffee'

app.service "rmapsEventsLinkerService", ($rootScope, nemSimpleLogger, rmapsNgLeafletHelpersService, leafletDrawEvents) ->
  $log = nemSimpleLogger.spawn("map:rmapsEventsLinkerService")
  leafletEvents = rmapsNgLeafletHelpersService.events
  _getMapIdEventStr = rmapsNgLeafletHelpersService.events.getMapIdEventStr

  _getArgs = (args, cb) ->
    unless cb
      throw new Error("rmapsEventsLinkerService._getArgs: cb is undefined")
    {leafletEvent, leafletObject, model, modelName, layerName} = args
    return unless model
    cb(leafletEvent, leafletObject, model, modelName, layerName)

  hookMarkers = (mapId, handler, originator, markerEvents = leafletEvents.markerEvents) ->
    #return a array of unsubscibers if you want to early unsubscibe
    markerEvents.map (name) ->
      eventName = "leafletDirectiveMarker.#{_getMapIdEventStr(mapId)}" + name
      $rootScope.$onRootScope eventName, (event, args) ->
        if name == 'click'
          s = 'click'

        _getArgs args, (leafletEvent, leafletObject, model, modelName, layerName) ->
          if handler[name]?
            return if layerName == 'addresses'#IF the ignore list grows.. make an array
            handler[name](leafletEvent, leafletObject, model, modelName, layerName, 'marker', originator)

  hookGeoJson = (mapId, handler, originator, geojsonEvents = leafletEvents.geojsonEvents) ->
    #return a array of unsubscibers if you want to early unsubscibe
    geojsonEvents.map (name) ->
      eventName = "leafletDirectiveGeoJson.#{_getMapIdEventStr(mapId)}" + name
      $rootScope.$onRootScope eventName, (event, args) ->
        if name == 'click'
          s = 'click'

        _getArgs args, (leafletEvent, leafletObject, model, modelName, layerName) ->
          {feature} = leafletObject
          return unless feature
          feature.coordinates = feature.geometry_center.coordinates #makes resultsFormatter happy TODO: getCoords func ?
          if handler[name]?
            handler[name](leafletEvent, leafletObject, feature, feature.rm_property_id, layerName, 'geojson', originator)

  hookMap = (mapId, handler, originator, mapEvents) ->
    #return a array of unsubscibers if you want to early unsubscibe
    mapEvents.map (name) ->
      eventName = "leafletDirectiveMap.#{_getMapIdEventStr(mapId)}" + name
      $rootScope.$onRootScope eventName, (event, args) ->
        _getArgs args, (leafletEvent, leafletObject, model, modelName, layerName) ->

          if handler[name]?
            handler[name](leafletEvent, leafletObject, model,  modelName, layerName, 'map', originator)

  {
    hookMarkers
    hookGeoJson
    hookMap
  }
