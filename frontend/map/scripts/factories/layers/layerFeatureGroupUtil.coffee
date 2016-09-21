app = require '../../app.coffee'
_ =  require 'lodash'

app.factory 'rmapsFeatureGroupUtil', ($log) ->

  $log = $log.spawn('rmapsFeatureGroupUtil')

  (featureGroup) ->
    origFillOpacity = null
    firstSetOpacity = true

    featureGroup.on 'mouseout', ({layer} = {}) =>
      $log.debug 'shape mouseout'
      @onMouseLeave(layer)

    featureGroup.on 'mouseover', ({layer} = {}) =>
      $log.debug 'shape  mouseover'
      @onMouseOver(layer)

    @getLayer = (geojsonModel) ->
      if !geojsonModel?.properties?.id?
        return
      for key, val of featureGroup._layers
        if val.model.properties?.id == geojsonModel.properties.id
          item = val
          break
      item


    @setDrawItemColor =({entity, fillColor, fillOpacity, firstOpacity}) ->
      drawItem = if entity.setStyle? then entity else @getLayer(entity)

      if firstSetOpacity && firstOpacity
        firstSetOpacity = false
        origFillOpacity = drawItem.options.fillOpacity

      options = {
        fillColor
        fillOpacity
      }
      drawItem.setStyle(_.cleanObject options)

    @onMouseLeave = (entity) ->
      @setDrawItemColor {entity,fillOpacity: origFillOpacity}

    @onMouseOver = (entity) ->
      @setDrawItemColor {entity, fillOpacity: .65, firstOpacity: true}

    @
