app = require '../app.coffee'

app.factory 'rmapsHoverQueue', (
rmapsLayerFormattersService
) ->
  () ->
    _queue = []

    _handleHover = ({model, lObject, type, layerName} = {}) ->
      return if !layerName or !type or !lObject
      if type == 'marker' and layerName != 'addresses' and model.markerType != 'note'
        rmapsLayerFormattersService.MLS.setMarkerOptions(model)
      if type == 'geojson'
        opts = rmapsLayerFormattersService.Parcels.getStyle(model, layerName)
        lObject.setStyle(opts)

    enqueue = ({model, lObject, type, layerName} = {}) ->
      if _queue.length
        dequeue()
      _queue.push {model, lObject, type, layerName}
      _handleHover {model, lObject, type, layerName}

    dequeue = () ->
      item = _queue.shift()
      if !item
        return
      {model, lObject, type, layerName} = item
      model.isMousedOver = false
      _handleHover {model, lObject, type, layerName}


    {
      enqueue
      dequeue
    }
