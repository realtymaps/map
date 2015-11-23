app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mapId = 'mainMap'
originator = 'map'
domainName = 'MapDraw'
controllerName = "#{domainName}Ctrl"

#TODO: get colors from color palette

app.controller "rmaps#{controllerName}", ($scope, $log, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate,
leafletIterators, toastr, leafletData, leafletDrawEvents, rmapsprincipal, rmapsProjectsService) ->
  # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
  $log = $log.spawn("map:#{controllerName}")
  drawnShapesSvc = rmapsProjectsService.drawnShapes

  _syncDrawnShapes = () ->
    drawnShapesSvc.update drawnItems.toGeoJSON()

  rmapsprincipal.getCurrentProfile().then (profile) ->
    $log.debug('profile')
    $log.debug(profile)
    drawnShapesSvc.getAll().then (drawnShapes) ->
      # # TODO: drawn shapes will get its own tables for GIS queries
      geoJson = L.geoJson drawnShapes,
        onEachFeature: (feature, layer) ->
          if feature.properties?.shapeType = 'Circle'
            layer = L.Circle.createFromFeature feature
          drawnItems.addLayer layer

  _toast = null
  drawnItems = new L.FeatureGroup()

  #call this on every shape change to save shapes

  _.merge $scope,
    map:
      drawState: {}
      leafletDrawOptions:
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
      events:
        draw:
          enable: leafletDrawEvents.getAvailableEvents()

  leafletData.getMap(mapId).then (lMap) ->
    lMap.addLayer(drawnItems)

    _linker = rmapsMapEventsLinkerService
    _it = leafletIterators

    _endDrawAction = () ->
      toastr.clear _toast
      rmapsNgLeafletEventGate.enableMapCommonEvents(mapId)

    _destroy = () ->
      _it.each _unsubscribes, (unsub) -> unsub()

    _doToast = (msg, contextName) ->
      _toast = toastr.info msg, contextName,
        closeButton: true
        timeOut: 0
        onHidden: (hidden) ->
          _endDrawAction()

      rmapsNgLeafletEventGate.disableMapCommonEvents(mapId)

    $scope.$on '$destroy', ->
      _destroy()
      $log.debug('destroyed')

    #see https://github.com/michaelguild13/Leaflet.draw#events
    _handle =
      created: ({layer,layerType}) ->
        drawnItems.addLayer(layer)
        _syncDrawnShapes()
      edited: ({layers}) ->
      deleted: ({layers}) ->
        drawnItems.removeLayer(layer)
        _syncDrawnShapes()
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

    _handle = _.mapKeys _handle, (val, key) -> 'draw:' + key
    _unsubscribes = _linker.hookDraw(mapId, _handle, originator)

    $log.debug 'loaded'
