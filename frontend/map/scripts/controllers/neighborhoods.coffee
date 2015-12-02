###global _:true, L:true ###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighborhoods.jade'
mapId = 'mainMap'
originator = 'map'
popupTemplate = require '../../html/includes/map/_notesPopup.jade'

app.controller 'rmapsNeighborhoodsCtrl', ($rootScope, $scope, $modal, rmapsNotesService, rmapsMainOptions, rmapsevents) ->
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

    createNeighborhood: (model) ->
      $scope.createModal().then (lModle) ->
        _.extend lModle,
          rm_property_id : model.rm_property_id || undefined
          geom_point_json : model.geom_point_json
          project_id: $scope.selectedProject.project_id || undefined
        _signalUpdate rmapsNotesService.create lModle

    updateNote: (note) ->
      note = _.cloneDeep note
      $scope.createModal(note).then (note) ->
        _signalUpdate rmapsNotesService.update note

    removeNote: (note) ->
      _signalUpdate rmapsNotesService.remove note.id

#this should be nested under rmapsNotesCtrl to be able to create modals
.controller 'rmapsMapNeighborhoodsTapCtrl', ($scope, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate,
  leafletIterators, toastr, $log) ->

  linker = rmapsMapEventsLinkerService
  $log = $log.spawn("map:rmapsMapNeighborhoodsTapCtrl")

  $scope.$on '$destroy', ->
    $log.debug('destroyed')

  _destroy = () ->
    toastr.clear noteToast
    rmapsNgLeafletEventGate.enableMapCommonEvents(mapId)

    leafletIterators.each unsubscribes, (unsub) ->
      unsub()
    $scope.Toggles.showNoteTap = false

  noteToast = toastr.info 'Click on the Map to Assign a Note to a location or property', 'Create a Note',
    closeButton: true
    timeOut: 0
    onHidden: (hidden) ->
      _destroy()

  rmapsNgLeafletEventGate.disableMapCommonEvents(mapId)

  _mapHandle =
    click: (event) ->
      geojson = (new L.Marker(event.latlng)).toGeoJSON()
      $scope.createGeoNote
        geom_point_json: geojson.geometry
      .finally ->
        _destroy()

  _markerGeoJsonHandle =
    click: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
      $log.debug "note for model: #{model.rm_property_id}"
      $scope.createGeoNote(model).finally ->
        _destroy()

  mapUnSubs = linker.hookMap(mapId, _mapHandle, originator, ['click'])
  markersUnSubs = linker.hookMarkers(mapId, _markerGeoJsonHandle, originator)
  geoJsonUnSubs = linker.hookGeoJson(mapId, _markerGeoJsonHandle, originator)

  unsubscribes = mapUnSubs.concat markersUnSubs, geoJsonUnSubs

.controller 'rmapsMapNeighborhoodsCtrl', ($rootScope, $scope, $http, $log, rmapsNotesService,
rmapsevents, rmapsLayerFormatters, leafletData, leafletIterators, rmapsPopupLoader, rmapsMapEventsLinkerService) ->

  setMarkerNotesOptions = rmapsLayerFormatters.MLS.setMarkerNotesOptions
  setDataOptions = rmapsLayerFormatters.setDataOptions
  linker = rmapsMapEventsLinkerService

  popup = rmapsPopupLoader
  markersUnSubs = null

  $log = $log.spawn("map:neighborhoods")

  _.merge $scope,
    map:
      markers:
        notes:[]

  leafletData.getMap(@mapId).then (lMap) ->
    _markerGeoJsonHandle =
      mouseout: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
        return if model.markerType != 'note'
        popup.close()

      mouseover: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
        return if model.markerType != 'note'
        popup.load($scope, lMap, model, undefined, undefined,
          popupTemplate({title:model.title, text: model.text, circleNrArg: model.$index + 1}), false)

    markersUnSubs = linker.hookMarkers(mapId, _markerGeoJsonHandle, originator)

  $scope.$on '$destroy', ->
    if _.isArray markersUnSubs
      leafletIterators.each markersUnSubs, (unsub) ->
        unsub()

  getNotes = () ->
    rmapsNotesService.getList().then (data) ->
      $log.debug "received note data #{data.length} " if data?.length
      $scope.map.markers.notes = setDataOptions data, setMarkerNotesOptions

  $scope.map.getNotes = getNotes

  # $scope.$watch 'Toggles.showNeighborhoods', (newVal) ->

  $rootScope.$onRootScope rmapsevents.neighborhoods, ->
    getNotes()

  getNotes()
