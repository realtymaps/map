app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
notesTemplate = do require '../../html/views/templates/modals/note.jade'

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

    createFromProperty: (property) ->
      $scope.createModal().then (note) ->
        _.extend note,
          rm_property_id : property.rm_property_id
          geom_point_json : property.geom_point_json

        _signalUpdate rmapsNotesService.create note

    updateNote: (note) ->
      note = _.cloneDeep note
      $scope.createModal(note).then (note) ->
        _signalUpdate rmapsNotesService.update note

    removeNote: (note) ->
      _signalUpdate rmapsNotesService.remove note.id

#this should be nested under rmapsNotesCtrl to be able to create modals
.controller 'rmapsMapNotesTapCtrl', ($scope, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate, leafletIterators, toastr, rmapsMapNotesTapCtrlLogger) ->
  $log = rmapsMapNotesTapCtrlLogger

  mapId = 'mainMap'
  originator = 'map'

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
      $log.debug "note from map"
      $log.debug event.latlng
      #TODO: convert LatLong to geoJson Point and save to geom_point_json
      $scope.createModal().finally ->
        _destroy()

  _markerGeoJsonHandle =
    click: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
      $log.debug "note for model: #{model.rm_property_id}"
      $scope.createFromProperty(model).finally ->
        _destroy()

  mapUnSubs = rmapsMapEventsLinkerService.hookMap(mapId, _mapHandle, originator, ['click'])
  markersUnSubs = rmapsMapEventsLinkerService.hookMarkers(mapId, _markerGeoJsonHandle, originator)
  geoJsonUnSubs = rmapsMapEventsLinkerService.hookGeoJson(mapId, _markerGeoJsonHandle, originator)

  unsubscribes = mapUnSubs.concat markersUnSubs, geoJsonUnSubs

.controller 'rmapsMapNotesCtrl', ($rootScope, $scope, $http, $log, rmapsNotesService, rmapsevents) ->
  $log = $log.spawn("map:notes")

  $scope.notes = []

  promiseCacheIsDisabled = false

  getNotesPromise = () ->
    rmapsNotesService.getList()

  getNotes = () ->
    getNotesPromise().then (data) ->
      $log.debug "received note data #{data.length} " if data?.length
      $scope.notes = data

  $rootScope.$onRootScope rmapsevents.notes, ->
    getNotes()

  getNotes()
