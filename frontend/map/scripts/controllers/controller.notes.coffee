###global _, L###
app = require '../app.coffee'
notesTemplate = do require '../../html/views/templates/modals/note.jade'
confirmTemplate = do require '../../html/views/templates/modals/confirm.jade'
originator = 'map'
_ = require 'lodash'
L = require 'leaflet'



app.controller 'rmapsNotesModalCtrl', (
$rootScope
$scope
$uibModal
rmapsNotesService
rmapsMainOptions
rmapsEventConstants
rmapsPrincipalService
rmapsMapTogglesFactory
) ->

  # Turn on the Notes map layer then zoom to the property
  $scope.centerOn = (model) ->
    rmapsMapTogglesFactory.currentToggles.showNotes = true
    $rootScope.$emit rmapsEventConstants.map.zoomToProperty, model

  _signalUpdate = (promise) ->
    return $rootScope.$emit rmapsEventConstants.notes unless promise
    promise.then (result) ->
      $rootScope.$emit rmapsEventConstants.notes, result

  $scope.activeView = 'notes'

  $scope.hasNotes = (property) ->
    rmapsNotesService.hasNotes(property?.rm_property_id)

  $scope.createModal = (note = {}, property) ->
    modalScope = $scope.$new false
    modalScope.property = property

    modalInstance = $uibModal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: notesTemplate
      scope: modalScope
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> note

    modalInstance.result

  $scope.create = (property, projectId) ->
    $scope.createModal({}, property).then (note) ->
      _.extend note,
        rm_property_id : property.rm_property_id || undefined
        geometry_center : property.geometry_center
        project_id: projectId || rmapsPrincipalService.getCurrentProfile().project_id || undefined

      # Turn the Notes layer on so that the user will see the new note
      rmapsMapTogglesFactory.currentToggles.showNotes = true
      _signalUpdate rmapsNotesService.create note

  $scope.update = (note, property) ->
    note = _.cloneDeep note
    $scope.createModal(note, property).then (note) ->
      _signalUpdate rmapsNotesService.update note

  $scope.remove = (note, confirm = false) ->
    if confirm
      modalInstance = $uibModal.open
        scope: $scope
        template: confirmTemplate

      $scope.showCancelButton = true
      $scope.modalTitle = "Remove note \"#{note.title}\"?"
      $scope.modalCancel = modalInstance.dismiss
      $scope.modalOk = () ->
        modalInstance.close()
        _signalUpdate rmapsNotesService.remove note.id
    else
      _signalUpdate rmapsNotesService.remove note.id

.controller 'rmapsMapNotesTapCtrl',(
  $log
  $scope,
  leafletIterators,
  rmapsEventsLinkerService,
  rmapsNgLeafletEventGateService,
  toastr
  rmapsCurrentMapService
) ->

  mapId = rmapsCurrentMapService.mainMapId()
  linker = rmapsEventsLinkerService
  $log = $log.spawn("map:rmapsMapNotesTapCtrlLogger")
  createFromModal = $scope.create

  $scope.$on '$destroy', ->
    $log.debug('destroyed')

  _destroy = () ->
    toastr.clear noteToast
    rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)

    leafletIterators.each unsubscribes, (unsub) ->
      unsub()
    $scope.Toggles.showNoteTap = false

  noteToast = toastr.info 'Click on the Map to Assign a Note to a location or property', 'Create a Note',
    closeButton: true
    timeOut: 0
    onHidden: (hidden) ->
      _destroy()

  rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)

  _mapHandle =
    #create a note from purley land
    click: (event) ->
      geojson = (new L.Marker(event.latlng)).toGeoJSON()
      createFromModal
        geometry_center: geojson.geometry
      .finally ->
        _destroy()

  _markerGeoJsonHandle =
    #create a note from an existing parcel
    click: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
      $log.debug "note for model: #{model.rm_property_id}"
      createFromModal(model).finally ->
        _destroy()

  mapUnSubs = linker.hookMap(mapId, _mapHandle, originator, ['click'])
  markersUnSubs = linker.hookMarkers(mapId, _markerGeoJsonHandle, originator)
  geoJsonUnSubs = linker.hookGeoJson(mapId, _markerGeoJsonHandle, originator)

  unsubscribes = mapUnSubs.concat markersUnSubs, geoJsonUnSubs

.controller 'rmapsMapNotesCtrl', (
  $rootScope,
  $scope,
  $http,
  $log,
  leafletData,
  leafletIterators,
  rmapsEventConstants,
  rmapsLayerFormattersService,
  rmapsEventsLinkerService,
  rmapsNotesService,
  rmapsPopupLoaderService,
  rmapsCurrentMapService,
  toastr
) ->

  mapId = rmapsCurrentMapService.mainMapId()
  {setMarkerNotesDataOptions} = rmapsLayerFormattersService
  linker = rmapsEventsLinkerService
  directiveControls = null
  popup = rmapsPopupLoaderService
  markersUnSubs = null

  leafletData.getDirectiveControls(mapId).then (controls) ->
    directiveControls = controls

  $log = $log.spawn("map:notes")

  _.merge $scope,
    map:
      markers:
        notes:[]

  leafletData.getMap(mapId).then (lMap) ->
    _markerGeoJsonHandle =
      mouseout: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
        return if model.markerType != 'note'
        popup.close()

      mouseover: (event, lObject, model, modelName, layerName, type, originator, maybeCaller) ->
        return if model.markerType != 'note'
        popup.load({
          map: lMap
          model
          templateVars:
            title: model.title
            first_name: model.first_name
            last_name: model.last_name
            text: model.text
            circleNrArg: model.$index
            address: model.address
          needToCompile: true
        })

    markersUnSubs = linker.hookMarkers(mapId, _markerGeoJsonHandle, originator)

  $scope.$on '$destroy', ->
    if _.isArray markersUnSubs
      leafletIterators.each markersUnSubs, (unsub) ->
        unsub()

  $scope.notesListLength = () ->
    if !$scope.map?.notesList?
      return 0
    Object.keys($scope.map.notesList).length

  getNotes = (force = false) ->
    rmapsNotesService.getAll(force)
    .then (data) ->
      $log.debug "received note data"

      # Enable notes layer if a new note is found after initial load
      if $scope.map.notesList
        newNotes = _.difference(_.keys(data), _.keys($scope.map.notesList))
        if newNotes.length && "#{data[newNotes[0]].auth_user_id}" != "#{$rootScope.identity.user?.id}"
          msg = "New note from #{data[newNotes[0]].first_name}"
          $log.debug msg
          noteToast = toastr.info msg, data[newNotes[0]].text,
            closeButton: true
            timeOut: 0
            onHidden: (hidden) ->
              toastr.clear noteToast
          $scope.map.layers.overlays?.notes?.visible = true

      $scope.map.notesList = data
      $scope.map.markers.notes = setMarkerNotesDataOptions(data)

  $rootScope.$onRootScope rmapsEventConstants.notes, ->
    getNotes(true)
    .then (notes) ->
      ###
        NOTE this is highly dangerous if the map is moved and we update notes at the same time. As there is currently a race condition
        in markers.js in angular-leaflet . So if we start seeing issues then all drawing should go through map.draw() from mapFactory
        #https://github.com/tombatossals/angular-leaflet-directive/issues/820
      ###

      # TODO This is ugly due to ui-leaflet
      # delete old notes from map to force list and map to be in sync
      $scope.map.markers.notes = {}
      directiveControls.markers.create($scope.map.markers)#<-- me dangerous
      # set new notes
      $scope.map.markers.notes = notes
      directiveControls.markers.create($scope.map.markers)#<-- me dangerous

  $scope.map.getNotes = _.throttle getNotes, 30000, leading: true, trailing: false

  $scope.$watch 'Toggles.showNotes', (newVal) ->
    $scope.map.layers.overlays?.notes?.visible = !!newVal

  $scope.$watch 'map.layers.overlays.notes', (newVal) ->
    $scope.map.layers.overlays?.notes?.visible = !!$scope.Toggles?.showNotes

  getNotes()
