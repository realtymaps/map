###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNotesService', (
$rootScope
$http
$log
rmapsEventConstants
rmapsPrincipalService
rmapsHttpTempCache
) ->
  $log = $log.spawn('rmapsNotesService')

  getPromise = null
  _notes = {}

  service =
    # Restangular.service backendRoutes.notesSession.apiBase
    # vs a simple $http
    getAll: (force = false, cache = true) ->
      $log.debug 'Get notes from API, force?', force
      if !getPromise || force
        if force
          cache = false

        project_id = rmapsPrincipalService.getCurrentProjectId()
        url = backendRoutes.notesSession.apiBase + "?project_id=#{project_id}"

        rmapsHttpTempCache {
          url
          promise: $http.getData(url, {cache})
          .then (data) ->
            index = 0
            for key, val of data
              val.$index = ++index
              val.text = decodeURIComponent(val.text)
            _notes = data
          ttlMilliSec: 800
        }
      else
        getPromise

    getList: (force, cache) ->
      @getAll(force, cache).then (data) ->
        _.values data

    createFromText: ({text, project_id, rm_property_id, geometry_center} = {}) ->
      note = {
        text
        rm_property_id
        geometry_center
        project_id: project_id || rmapsPrincipalService.getCurrentProfile().project_id || undefined
      }

      service.create(note)

    createNote: ({project, property, $scope} = {}) ->
      @createFromText({
        text: $scope.newNotes[property.rm_property_id].text
        project_id: project.project_id
        rm_property_id: property.rm_property_id
        geometry_center: property.geometry_center
      }).then (result) ->
        $rootScope.$emit rmapsEventConstants.notes
        delete $scope.newNotes[property.rm_property_id]
        result

    createProjectNote: ({project, $scope} = {}) ->
      @createFromText({
        text: $scope.newNotes['project'].text,
        project_id: project.project_id
      }).then (result) ->
        $rootScope.$emit rmapsEventConstants.notes
        delete $scope.newNotes['project']
        result

    create: (entity) ->
      entity.text = encodeURIComponent(entity.text)
      $http.post(backendRoutes.notesSession.apiBase, entity, {cache:false})
      .then ({data}) =>
        @getList(true)
        data

    remove: (id) ->
      throw new Error('must have id') unless id
      id = '/' + id if id
      $http.delete(backendRoutes.notesSession.apiBase + id)
      .then () =>
        @getList(true)

    update: (entity) ->
      entity.text = encodeURIComponent(entity.text)
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(backendRoutes.notesSession.apiBase + id, entity, cache: false)
      .then ({data}) =>
        @getList(true)
        data

    hasNotes: (propertyId) ->
      return false unless propertyId

      !!_.find _notes, (note) ->
        note.rm_property_id == propertyId

    clear: () ->
      _notes = {}

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, profile) ->
    $log.debug 'Notes Service profile updated event'
    service.getList true

  $rootScope.$onRootScope rmapsEventConstants.principal.logout.success, (event, profile) ->
    $log.debug 'Notes Service user logout event'
    service.clear()

  return service
