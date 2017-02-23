_ = require 'lodash'
app = require '../app.coffee'

app.factory "rmapsDrawCtrlFactory", (
$q
$rootScope
$log
rmapsNgLeafletEventGateService
toastr
leafletData
leafletDrawEvents
rmapsDrawnUtilsService
) ->
  {eachLayerModel} = rmapsDrawnUtilsService
  ngLog = $log


  ({$scope, mapId, handleOptions, drawnItems, name, itemsOptions, drawOptions, featureGroupUtil, drawnShapesSvc}) ->

    createHandles = ({endDrawAction, commonPostDrawActions, announceCb, createPromise, deleteAction}) ->
      endDrawAction ?= ->
      commonPostDrawActions ?= ->
      deleteAction ?= ->
      announceCb ?= ->

      drawnItems.getLayers().forEach (layer) ->
        _.extend(layer.options, itemsOptions)

      "draw:created": ({layer,layerType}) ->
        _.extend(layer.options, itemsOptions)
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

      "draw:edited": ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.update(model).then ->
            commonPostDrawActions(model)

      "draw:deleted": ({layers}) ->
        eachLayerModel layers, (model) ->
          drawnShapesSvc?.delete(model).then ->
            commonPostDrawActions(model)
            deleteAction?(model)

      ### eslint-disable ###
      "draw:drawstart": ({layerType}) ->
      "draw:drawstop": ({layerType}) ->
        ### eslint-disable ###

      "draw:editstart": ({handler}) ->
        featureGroupUtil.onOffPointerEvents({isOn:true})

      "draw:editstop": ({handler}) ->
        featureGroupUtil.onOffPointerEvents({isOn:false})

      "draw:deletestart": ({handler}) ->
        announceCb('Delete Drawing','Delete Drawing')
        featureGroupUtil.onOffPointerEvents({isOn:true})
        return

      "draw:deletestop": ({handler}) ->
        featureGroupUtil.onOffPointerEvents({isOn:false})
        endDrawAction()
        return

    _handles = createHandles(handleOptions)

    init = ({enable}) ->
      handles = if enable then _handles else null

      if !handles?
        featureGroupUtil.onOffPointerEvents({isOn:false})
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
      else
        featureGroupUtil.onOffPointerEvents({isOn:true})
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)


      $scope.draw =
        ready: false

      # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
      $log = ngLog.spawn("map:rmapsDrawCtrlFactory:#{name}")


      if drawnItems?._layers?
        ngLog.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

      mapPromise = leafletData.getMap(mapId)

      mapPromise.then () ->

        _destroy = () ->

        _.extend $scope.draw,
          mapPromise: mapPromise
          drawState: {}
          leafletDrawEvents: handles
          leafletDrawOptions: _.merge(
            ngOptions:
              cssClass: 'btn btn-transparent nav-btn'
            position:"bottomright"
            draw:
              polyline:
                metric: false
              polygon:
                metric: false
                showArea: true
                drawError:
                  color: '#b00b00' #TODO change colors to map theme
                  timeout: 1000
                shapeOptions:
                  color: '#bada55' #TODO change colors to map theme
              circle:
                showArea: true
                metric: false
                shapeOptions:
                  color: '#662d91' #TODO change colors to map theme
              marker: false
            edit:
              featureGroup: drawnItems
              remove: true
          , drawOptions || {})
          events:
            draw:
              enable: leafletDrawEvents

        $scope.$on '$destroy', ->
          # need to disable events for shapes
          _destroy()
          $log.debug('destroyed')
        #END SCOPE Extensions

        $log.debug 'loaded'
        $scope.draw.ready = true

    return {
      init
    }
