###global _:true, L:true ###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighborhood.jade'
mapId = 'mainMap'
originator = 'map'

app.controller 'rmapsNeighborhoodsModalCtrl', ($rootScope, $scope, $modal, rmapsNotesService, rmapsMainOptions, rmapsevents) ->
  _event = rmapsevents.neighborhoods

  _signalUpdate = (promise) ->
    return $rootScope.$emit _event unless promise
    promise.then ->
      $rootScope.$emit _event

  _.extend $scope,
    activeView: 'neighborhoods'

    createModal: (neighborhood = {}) ->
      modalInstance = $modal.open
        animation: rmapsMainOptions.modals.animationsEnabled
        template: template
        controller: 'rmapsModalInstanceCtrl'
        resolve: model: -> neighborhood

      modalInstance.result

    create: (model) ->
      $scope.createModal().then (lModle) ->
        _.extend lModle,
          rm_property_id : model.rm_property_id || undefined
          geom_point_json : model.geom_point_json
          project_id: $scope.selectedProject.project_id || undefined
        _signalUpdate rmapsNotesService.create lModle

    update: (note) ->
      note = _.cloneDeep note
      $scope.createModal(note).then (note) ->
        _signalUpdate rmapsNotesService.update note

    remove: (note) ->
      _signalUpdate rmapsNotesService.remove note.id

.controller 'rmapsMapNeighborhoodsTapCtrl', ($scope, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate,
  leafletIterators, toastr, $log) ->

  linker = rmapsMapEventsLinkerService
  $log = $log.spawn("map:rmapsMapNeighborhoodsTapCtrl")

  $scope.$on '$destroy', ->
    $log.debug('destroyed')

  _destroy = () ->
    toastr.clear toast
    rmapsNgLeafletEventGate.enableMapCommonEvents(mapId)

    leafletIterators.each unsubscribes, (unsub) ->
      unsub()
    $scope.Toggles.showNeighborhoodTap = false

  toast = toastr.info 'Assign a shape (Circle, Polygon, or Square) by clicking one.', 'Create a Neighborhood',
    closeButton: true
    timeOut: 0
    onHidden: (hidden) ->
      _destroy()

  rmapsNgLeafletEventGate.disableMapCommonEvents(mapId)

  _mapHandle =
    click: (event) ->
      geojson = (new L.Marker(event.latlng)).toGeoJSON()
      $scope.create
        geom_point_json: geojson.geometry
      .finally ->
        _destroy()

  _markerGeoJsonHandle =
    click: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
      $log.debug "note for model: #{model.rm_property_id}"
      $scope.create(model).finally ->
        _destroy()

  mapUnSubs = linker.hookMap(mapId, _mapHandle, originator, ['click'])
  markersUnSubs = linker.hookMarkers(mapId, _markerGeoJsonHandle, originator)
  geoJsonUnSubs = linker.hookGeoJson(mapId, _markerGeoJsonHandle, originator)

  unsubscribes = mapUnSubs.concat markersUnSubs, geoJsonUnSubs

.controller 'rmapsMapNeighborhoodsCtrl', ($rootScope, $scope, $http, $log, rmapsNotesService,
rmapsevents, rmapsLayerFormatters, leafletData, leafletIterators, rmapsMapEventsLinkerService) ->


  $log = $log.spawn("map:neighborhoods")


  $scope.$on '$destroy', ->
    if _.isArray markersUnSubs
      leafletIterators.each markersUnSubs, (unsub) ->
        unsub()

  getAll = () ->
    rmapsNotesService.getList().then (data) ->
      $log.debug "received data #{data.length} " if data?.length
      $scope.neighborhoods = data

  $scope.map.getAll = getAll

  $rootScope.$onRootScope rmapsevents.neighborhoods, ->
    getAll()

  getAll()
