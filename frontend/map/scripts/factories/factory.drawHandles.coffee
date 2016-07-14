###globals _###
app = require '../app.coffee'

app.factory "rmapsMapDrawHandlesFactory", ($log, rmapsDrawnUtilsService, rmapsNgLeafletEventGateService) ->

  {eachLayerModel} = rmapsDrawnUtilsService
  $log = $log.spawn("map:rmapsMapDrawHandlesFactory")

  _makeDrawKeys = (handles) ->
    _.mapKeys handles, (val, key) -> 'draw:' + key

  return ({drawnShapesSvc, drawnItems, endDrawAction, commonPostDrawActions, announceCb, createPromise, mapId, deleteAction}) ->

    _makeDrawKeys
      ### eslint-disable ###
      created: ({layer,layerType}) ->
        ### eslint-enable ###
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

      ### eslint-disable ###
      drawstart: ({layerType}) ->
        ### eslint-enable ###
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
        announceCb('Draw on the map to query polygons and shapes','Draw')

      ### eslint-disable ###
      drawstop: ({layerType}) ->
        ### eslint-enable ###
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
        endDrawAction()

      ### eslint-disable ###
      editstart: ({handler}) ->
        ### eslint-enable ###
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
        announceCb('Edit Drawing on the map to query polygons and shapes','Edit Drawing')

      ### eslint-disable ###
      editstop: ({handler}) ->
        ### eslint-enable ###
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
        endDrawAction()

      ### eslint-disable ###
      deletestart: ({handler}) ->
        ### eslint-enable ###
        announceCb('Delete Drawing','Delete Drawing')

      ### eslint-disable ###
      deletestop: ({handler}) ->
        ### eslint-enable ###
        endDrawAction()
