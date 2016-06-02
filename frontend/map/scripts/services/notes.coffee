app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNotesService', ($rootScope, $http, $log, rmapsEventConstants, rmapsPrincipalService) ->
  $log = $log.spawn('rmapsNotesService')

  getPromise = null
  _notes = []

  service =
    # Restangular.service backendRoutes.notesSession.apiBase
    # vs a simple $http
    getList: (force = false) ->
      $log.debug 'Get notes from API, force?', force
      if !getPromise || force
        project_id = rmapsPrincipalService.getCurrentProjectId()
        getPromise = $http.get(backendRoutes.notesSession.apiBase, {cache: false, params: project_id: project_id}).then ({data}) ->
          _notes = data
          data
      else
        getPromise

    createFromText: (noteText, projectId, propertyId, geomPointJson) ->
      note = {
        text: noteText,
        rm_property_id : propertyId
        geom_point_json : geomPointJson
        project_id: projectId || rmapsPrincipalService.getCurrentProfile().project_id || undefined
      }

      return service.create(note)

    create: (entity) ->
      $http.post(backendRoutes.notesSession.apiBase, entity).then (response) ->
        service.getList true
        return response

    remove: (id) ->
      throw new Error('must have id') unless id
      id = '/' + id if id
      $http.delete(backendRoutes.notesSession.apiBase + id).then () ->
        service.getList true
        return

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(backendRoutes.notesSession.apiBase + id, entity).then () ->
        service.getList true
        return

    hasNotes: (propertyId) ->
      return false unless propertyId

      !!_.find _notes, (note) ->
        note.rm_property_id == propertyId

    clear: () ->
      getPromise = null
      _notes = []

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, profile) ->
    $log.debug 'Notes Service profile updated event'
    service.getList true

  $rootScope.$onRootScope rmapsEventConstants.principal.logout.success, (event, profile) ->
    $log.debug 'Notes Service user logout event'
    service.clear()

  return service

