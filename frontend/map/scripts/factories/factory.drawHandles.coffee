###globals _###
app = require '../app.coffee'

app.factory "rmapsMapDrawHandlesFactory", ($log, rmapsDrawnUtilsService) ->
  {eachLayerModel} = rmapsDrawnUtilsService
  $log = $log.spawn("map:rmapsMapDrawHandlesFactory")

  _makeDrawKeys = (handles) ->
    _.mapKeys handles, (val, key) -> 'draw:' + key

  return (opts) ->
    {drawnShapesSvc, drawnItems, endDrawAction, commonPostDrawActions, announceCb, create} = opts
    _makeDrawKeys
      created: ({layer,layerType}) ->
        drawnItems.addLayer(layer)
        geojson = layer.toGeoJSON()

        promise = create or drawnShapesSvc?.create
        promise(geojson).then ({data}) ->
          newId = data
          layer.model =
            properties:
              id: newId
          commonPostDrawActions(layer.model)
      edited: ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.update(model).then ->
            commonPostDrawActions(model)
      deleted: ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.delete(model).then ->
            commonPostDrawActions(model)
      drawstart: ({layerType}) ->
        announceCb('Draw on the map to query polygons and shapes','Draw')
      drawstop: ({layerType}) ->
        endDrawAction()
      editstart: ({handler}) ->
        announceCb('Edit Drawing on the map to query polygons and shapes','Edit Drawing')
      editstop: ({handler}) ->
        endDrawAction()
      deletestart: ({handler}) ->
        announceCb('Delete Drawing','Delete Drawing')
      deletestop: ({handler}) ->
        endDrawAction()
