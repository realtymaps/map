app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mapId = 'mainMap'
originator = 'map'
domainName = 'MapDraw'
controllerName = "#{domainName}Ctrl"

app.controller "rmaps#{controllerName}", ($scope, $log, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate,
leafletIterators, toastr, leafletData, leafletDrawEvents) ->
  _toast = null
  drawnItems = new L.FeatureGroup()

  _.merge $scope,
    map:
      leafletDrawOptions:
        position:"bottomright"
        draw:
          polyline:
            metric: false
          polygon:
            metric: false
            showArea: true
            drawError:
              color: '#b00b00',
              timeout: 1000
            shapeOptions:
              color: '#bada55'
          circle:
            showArea: true
            metric: false
            shapeOptions:
              color: '#662d91'
          marker: false
        edit:
          featureGroup: drawnItems
          remove: true
      events:
        draw:
          enable: leafletDrawEvents.getAvailableEvents()

  leafletData.getMap(mapId).then (lMap) ->
    lMap.addLayer(drawnItems)

    _linker = rmapsMapEventsLinkerService
    $log = $log.spawn("map:#{controllerName}")
    _it = leafletIterators

    _endDrawAction = () ->
      toastr.clear _toast
      rmapsNgLeafletEventGate.enableEvent(mapId, 'click')

    _destroy = () ->
      _it.each _unsubscribes, (unsub) -> unsub()

    _doToast = (msg, contextName) ->
      _toast = toastr.info msg, contextName,
        closeButton: true
        timeOut: 0
        onHidden: (hidden) ->
          _endDrawAction()

      rmapsNgLeafletEventGate.disableEvent(mapId, 'click')#disable click events temporarily for rmapsMapEventsHandler

    $scope.$on '$destroy', ->
      _destroy()
      $log.debug('destroyed')

    #see https://github.com/michaelguild13/Leaflet.draw#events
    _handle =
      created: ({layer,layerType}) ->
        drawnItems.addLayer(layer)
      edited: ({layers}) ->
      deleted: ({layers}) ->
        drawnItems.removeLayer(layer)
      drawstart: ({layerType}) ->
        _doToast('Draw on the map to query polygons and shapes','Draw')
      drawstop: ({layerType}) ->
        _endDrawAction()
      editstart: ({handler}) ->
        _doToast('Edit Drawing on the map to query polygons and shapes','Edit Drawing')
      editstop: ({handler}) ->
        _endDrawAction()
      deletestart: ({handler}) ->
        _doToast('Delete Drawing','Delete Drawing')
      deletestop: ({handler}) ->
        _endDrawAction()

    # L.DomUtil.get('changeColor').onclick = ->
    #   drawControl.setDrawingOptions({ rectangle: { shapeOptions: { color: '#004a80' } } })

    _handle = _.mapKeys _handle, (val, key) -> 'draw:' + key
    _unsubscribes = _linker.hookDraw(mapId, _handle, originator)

    $log.debug 'loaded'
