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
    getList: (force = false, cache = true) ->
      $log.debug 'Get notes from API, force?', force
      if !getPromise || force
        if force
          cache = false

        project_id = rmapsPrincipalService.getCurrentProjectId()
        url = backendRoutes.notesSession.apiBase + "?project_id=#{project_id}"

        rmapsHttpTempCache {
          url
          promise: $http.getData(url, {cache}).then (data) -> _notes = data
          ttlMilliSec: 800
        }
      else
        getPromise


    createFromText: (noteText, projectId, propertyId, geomPointJson) ->
      note = {
        text: noteText,
        rm_property_id : propertyId
        geometry_center : geomPointJson
        project_id: projectId || rmapsPrincipalService.getCurrentProfile().project_id || undefined
      }

      return service.create(note)

    create: (entity) ->
      $http.post(backendRoutes.notesSession.apiBase, entity, {cache:false})
      .then () =>
        @getList(true)

    remove: (id) ->
      throw new Error('must have id') unless id
      id = '/' + id if id
      $http.delete(backendRoutes.notesSession.apiBase + id)
      .then () =>
        @getList(true)

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(backendRoutes.notesSession.apiBase + id, entity, cache: false)
      .then () =>
        @getList(true)

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
