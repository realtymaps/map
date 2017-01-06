_ = require 'lodash'
app = require '../app.coffee'

app.factory "rmapsMapDrawHandlesFactory", ($q, $log, rmapsDrawnUtilsService, rmapsNgLeafletEventGateService) ->

  {eachLayerModel} = rmapsDrawnUtilsService
  $log = $log.spawn("map:rmapsMapDrawHandlesFactory")

  _makeDrawKeys = (handles) ->

    _.mapKeys handles, (val, key) -> 'draw:' + key

  return (options) ->
    {
      mapId
      drawnShapesSvc
      drawnItems
      endDrawAction
      commonPostDrawActions
      announceCb
      createPromise
      deleteAction
    } = options
    endDrawAction ?= ->
    commonPostDrawActions ?= ->
    deleteAction ?= ->
    announceCb ?= ->

    _makeDrawKeys
      ### eslint-disable ###
      created: ({layer,layerType}) ->
        ### eslint-enable ###
        drawnItems.addLayer(layer)
        geojson = layer.toGeoJSON()

        if layer.ignoreSave
          return $q.resolve()

        if createPromise
          promise = createPromise?(layer)
        else
          promise = drawnShapesSvc?.create(geojson)

        promise.then (result) ->
          if result?.data
            [id] = result.data
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

      ### eslint-disable ###
      drawstop: ({layerType}) ->

      ### eslint-disable ###
      editstart: ({handler}) ->

      ### eslint-disable ###
      editstop: ({handler}) ->

      ### eslint-disable ###
      deletestart: ({handler}) ->
        ### eslint-enable ###
        announceCb('Delete Drawing','Delete Drawing')
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)

      ### eslint-disable ###
      deletestop: ({handler}) ->
        ### eslint-enable ###
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
        endDrawAction()
