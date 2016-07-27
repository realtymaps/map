###global _, L###
app = require '../app.coffee'
notesTemplate = do require '../../html/views/templates/modals/note.jade'
confirmTemplate = do require '../../html/views/templates/modals/confirm.jade'
originator = 'map'

app.controller 'rmapsNotesModalCtrl', (
$rootScope
$scope
$modal
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
    promise.then ->
      $rootScope.$emit rmapsEventConstants.notes

  $scope.activeView = 'notes'

  $scope.hasNotes = (property) ->
    rmapsNotesService.hasNotes(property?.rm_property_id)

  $scope.createModal = (note = {}, property) ->
    modalScope = $scope.$new false
    modalScope.property = property

    modalInstance = $modal.open
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
      modalInstance = $modal.open
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
  rmapsMapEventsLinkerService,
  rmapsMapIds,
  rmapsNgLeafletEventGateService,
  toastr
) ->

  mapId = rmapsMapIds.mainMap()
  linker = rmapsMapEventsLinkerService
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
  rmapsMapEventsLinkerService,
  rmapsMapIds,
  rmapsNotesService,
  rmapsPopupLoaderService
) ->

  mapId = rmapsMapIds.mainMap()
  {setMarkerNotesDataOptions} = rmapsLayerFormattersService
  linker = rmapsMapEventsLinkerService
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
          needToCompile: false
        })

    markersUnSubs = linker.hookMarkers(mapId, _markerGeoJsonHandle, originator)

  $scope.$on '$destroy', ->
    if _.isArray markersUnSubs
      leafletIterators.each markersUnSubs, (unsub) ->
        unsub()

  $scope.markerNotesLength = () ->
    Object.keys($scope.map.markers.notes).length

  getNotes = (force = false) ->
    rmapsNotesService.getList(force)
    .then (data) ->
      $log.debug "received note data #{data.length} " if data?.length
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

  $scope.map.getNotes = getNotes

  $scope.$watch 'Toggles.showNotes', (newVal) ->
    $scope.map.layers.overlays.notes.visible = newVal


  getNotes()
