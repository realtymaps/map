###globals angular###
app = require '../../app.coffee'
_ =  require 'lodash'

app.factory 'rmapsFeatureGroupUtil', ($log) ->

  ({featureGroup, ownerName, events, @className}) ->
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


    ###
     NOTE:
     This function is one of the main reasons for this factory's existence.
     This was done to allow properties and markers under certain layers to be selectable. There for isOn allows the turns off/on
     the selectibility of a specific layer / drawItem.

     NOTE:
     Be sure to search css/stylus of `.rmaps-area, .rmaps-sketch` for their pointer-events settings.

    ###
    @onOffPointerEvents = ({isOn, className}) ->
      ele = document.getElementsByClassName(@className || className)
      ele = angular.element(ele)
      if isOn
        return ele?.css('pointer-events', 'auto')
      ele?.css('pointer-events', 'none')

    @
