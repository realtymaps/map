###globals _###
app = require '../app.coffee'

app.factory "rmapsMapDrawHandlesFactory", ($log, rmapsDrawnService) ->
  {eachLayerModel} = rmapsDrawnService
  $log = $log.spawn("map:rmapsMapDrawHandlesFactory")

  _makeDrawKeys = (handles) ->
    _.mapKeys handles, (val, key) -> 'draw:' + key

  return (opts) ->
    {drawnShapesSvc, drawnItems, endDrawAction, commonPostDrawActions, announceCb} = opts
    _makeDrawKeys
      created: ({layer,layerType}) ->
        drawnItems.addLayer(layer)
        drawnShapesSvc?.create(layer.toGeoJSON()).then ({data}) ->
          newId = data
          layer.model =
            properties:
              id: newId
          commonPostDrawActions()
      edited: ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.update(model).then ->
            commonPostDrawActions()
      deleted: ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.delete(model).then ->
            commonPostDrawActions()
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
