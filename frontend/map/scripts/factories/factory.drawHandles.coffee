###globals _###
app = require '../app.coffee'

app.factory "rmapsMapDrawHandlesFactory", ($log, rmapsDrawnUtilsService, rmapsNgLeafletEventGateService) ->

  {eachLayerModel} = rmapsDrawnUtilsService
  $log = $log.spawn("map:rmapsMapDrawHandlesFactory")

  _makeDrawKeys = (handles) ->
    _.mapKeys handles, (val, key) -> 'draw:' + key

  return ({drawnShapesSvc, drawnItems, endDrawAction, commonPostDrawActions, announceCb, createPromise, mapId, deleteAction}) ->

    _makeDrawKeys
      created: ({layer,layerType}) ->
        drawnItems.addLayer(layer)
        geojson = layer.toGeoJSON()

        promise = createPromise or drawnShapesSvc?.create
        promise(geojson).then ({data}) ->
          [id] = data
          layer.model =
            properties:
              id: id
          commonPostDrawActions(layer.model)

      edited: ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.update(model).then ->
            commonPostDrawActions(model)

      deleted: ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.delete(model).then ->
            commonPostDrawActions(model)
            deleteAction?(model)

      drawstart: ({layerType}) ->
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
        announceCb('Draw on the map to query polygons and shapes','Draw')

      drawstop: ({layerType}) ->
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
        endDrawAction()

      editstart: ({handler}) ->
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
        announceCb('Edit Drawing on the map to query polygons and shapes','Edit Drawing')

      editstop: ({handler}) ->
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
        endDrawAction()

      deletestart: ({handler}) ->
        announceCb('Delete Drawing','Delete Drawing')

      deletestop: ({handler}) ->
        endDrawAction()
