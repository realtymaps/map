app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNotesService', ($rootScope, $http, $log, rmapsEventConstants) ->
  $log = $log.spawn('rmapsNotesService')

  _notes = {}

  service =
    # Restangular.service backendRoutes.notesSession.apiBase
    # vs a simple $http
    getList: () ->
      $log.debug "Get notes from API"
      $http.get(backendRoutes.notesSession.apiBase, cache: false).then ({data}) ->
        _notes = data
        data

    create: (entity) ->
      $http.post(backendRoutes.notesSession.apiBase, entity)

    remove: (id) ->
      throw new Error('must have id') unless id
      id = '/' + id if id
      $http.delete(backendRoutes.notesSession.apiBase + id)

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(backendRoutes.notesSession.apiBase + id, entity)

    hasNotes: (propertyId) ->
      return false unless propertyId

      _.find _notes, (note) ->
        note.rm_property_id == propertyId

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, profile) ->
    $log.debug 'Notes Service profile updated event'
    service.getList()

  $rootScope.$onRootScope rmapsEventConstants.principal.logout.success, (event, profile) ->
    $log.debug 'Notes Service user logout event'
    _notes = {}

  return service

