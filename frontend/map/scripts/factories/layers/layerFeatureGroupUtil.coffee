###globals angular###
app = require '../../app.coffee'
_ =  require 'lodash'

app.factory 'rmapsFeatureGroupUtil', ($log) ->

  ({featureGroup, ownerName, events}) ->
    @$log = $log.spawn("rmapsFeatureGroupUtil:#{ownerName}")
    @$log.debug('initializing')

    origFillOpacity = null
    firstSetOpacity = true

    if events?.mouseout?
      featureGroup.on 'mouseout', ({layer} = {}) =>
        @$log.debug 'shape mouseout'
        @onMouseLeave(layer)

    if events?.mouseover?
      featureGroup.on 'mouseover', ({layer} = {}) =>
        @$log.debug 'shape  mouseover'
        @onMouseOver(layer)

    @getLayer = (geojsonModel) ->
      if !geojsonModel?.properties?.id?
        return
      # coffeelint: disable=check_scope
      for key, val of featureGroup._layers
      # coffeelint: enable=check_scope
        if val.model?.properties?.id == geojsonModel.properties.id
          item = val
          break
      item


    @setDrawItemColor =({entity, fillColor, fillOpacity, firstOpacity}) ->
      drawItem = if entity.setStyle? then entity else @getLayer(entity)

      if!drawItem
        @$log.debug 'undefined drawItem'
        return

      if firstSetOpacity && firstOpacity
        firstSetOpacity = false
        origFillOpacity = drawItem.options.fillOpacity

      options = {
        fillColor
        fillOpacity
      }
      opt = _.cleanObject(options)
      drawItem.setStyle(opt)

    @onMouseLeave = (entity) ->
      @setDrawItemColor {entity,fillOpacity: origFillOpacity}

    @onMouseOver = (entity) ->
      @setDrawItemColor {entity, fillOpacity: .45, firstOpacity: true}

    @onOffPointerEvents = ({isOn, className}) ->
      ele = document.getElementsByClassName(className)
      ele = angular.element(ele)
      if isOn
        return ele?.css('pointer-events', 'auto')
      ele?.css('pointer-events', 'none')

    @
