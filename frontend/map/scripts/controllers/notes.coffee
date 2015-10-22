app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
notesTemplate = do require '../../html/views/templates/modals/note.jade'
mapId = 'mainMap'
originator = 'map'
popupTemplate = require '../../html/includes/map/_notesPopup.jade'

app.controller 'rmapsModalNotesInstanceCtrl', ($scope, $modalInstance, note, $location) ->
  _.extend $scope,
    note: note

    save: ->
      $modalInstance.close $scope.note

    cancel: ->
      $modalInstance.dismiss 'cancel'

.controller 'rmapsNotesCtrl', ($rootScope, $scope, $modal, rmapsNotesService, rmapsMainOptions, rmapsevents) ->
  _signalUpdate = (promise) ->
    return $rootScope.$emit rmapsevents.notes unless promise
    promise.then ->
      $rootScope.$emit rmapsevents.notes

  _.extend $scope,
    activeView: 'notes'

    createModal: (note = {}) ->
      modalInstance = $modal.open
        animation: rmapsMainOptions.modals.animationsEnabled
        template: notesTemplate
        controller: 'rmapsModalNotesInstanceCtrl'
        resolve: note: -> note

      modalInstance.result

    createGeoNote: (model) ->
      $scope.createModal().then (note) ->
        _.extend note,
          rm_property_id : model.rm_property_id || undefined
          geom_point_json : model.geom_point_json
          project_id: $scope.selectedProfile.project_id || undefined
        _signalUpdate rmapsNotesService.create note

    updateNote: (note) ->
      note = _.cloneDeep note
      $scope.createModal(note).then (note) ->
        _signalUpdate rmapsNotesService.update note

    removeNote: (note) ->
      _signalUpdate rmapsNotesService.remove note.id

#this should be nested under rmapsNotesCtrl to be able to create modals
.controller 'rmapsMapNotesTapCtrl',
($scope, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate,
leafletIterators, toastr, rmapsMapNotesTapCtrlLogger) ->

  linker = rmapsMapEventsLinkerService
  $log = rmapsMapNotesTapCtrlLogger

  $scope.$on '$destroy', ->
    $log.debug('destroyed')

  _destroy = () ->
    toastr.clear noteToast
    rmapsNgLeafletEventGate.enableEvent(mapId, 'click')
    leafletIterators.each unsubscribes, (unsub) ->
      unsub()
    $scope.Toggles.showNoteTap = false

  noteToast = toastr.info 'Click on the Map to Assign a Note to a location or property', 'Create a Note',
    closeButton: true
    timeOut: 0
    onHidden: (hidden) ->
      _destroy()

  rmapsNgLeafletEventGate.disableEvent(mapId, 'click')#disable click events temporarily for rmapsMapEventsHandler

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

.controller 'rmapsMapNotesCtrl', ($rootScope, $scope, $http, $log, rmapsNotesService,
rmapsevents, rmapsLayerFormatters, leafletData, rmapsPopupLoader, rmapsMapEventsLinkerService) ->

  setMarkerNotesOptions = rmapsLayerFormatters.MLS.setMarkerNotesOptions
  setDataOptions = rmapsLayerFormatters.setDataOptions
  linker = rmapsMapEventsLinkerService
  directiveControls = null
  popup = rmapsPopupLoader
  markersUnSubs = null

  leafletData.getDirectiveControls('mainMap').then (controls) ->
    directiveControls = controls

  $log = $log.spawn("map:notes")

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
    markersUnSubs() if markersUnSubs?

  getNotes = () ->
    rmapsNotesService.getList().then (data) ->
      $log.debug "received note data #{data.length} " if data?.length
      $scope.map.markers.notes = setDataOptions data, setMarkerNotesOptions

  $scope.map.getNotes = getNotes

  $scope.$watch 'Toggles.showNotes', (newVal) ->
    $scope.map.layers.overlays.notes.visible = newVal

  $rootScope.$onRootScope rmapsevents.notes, ->
    getNotes().then ->
      ###
        NOTE this is highly dangerous if the map is moved and we update notes at the same time. As there is currently a race condition
        in markers.js in angular-leaflet . So if we start seeing issues then all drawing should go through map.draw() from mapFactory
        #https://github.com/tombatossals/angular-leaflet-directive/issues/820
      ###
      directiveControls.markers.create($scope.map.markers)#<-- me dangerous

  getNotes()
