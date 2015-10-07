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
