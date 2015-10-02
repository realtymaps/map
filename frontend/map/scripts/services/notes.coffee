app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsNotesService', (Restangular) ->
  Restangular.service backendRoutes.notesSession.apiBase
  #vs a simple $http
  # getList: () ->
  #   $http.get(backendRoutes.notesSession.apiBase, cache: false).then ({data}) ->
  #     data
  #
  # create: (entity) ->
  #   $http.post(backendRoutes.notesSession.apiBase, entity)
  #
  # remove: (id) ->
  #   throw new Error('must have id') unless id
  #   id = '/' + id if id
  #   $http.delete(backendRoutes.notesSession.apiBase + id)
  #
  # update: (entity) ->
  #   throw new Error('entity must have id') unless entity.id
  #   id = '/' + entity.id
  #   $http.put(backendRoutes.notesSession.apiBase + id, entity)
