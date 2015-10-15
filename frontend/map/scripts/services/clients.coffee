app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.factory 'rmapsClientsService', ($http) ->

  class ClientsService
    constructor: (@projectId) ->
      @endpoint = "#{backendRoutes.projectSession.root}/#{@projectId}/clients"

    getAll: (query) ->
      $http.get @endpoint, cache: false, params: query
      .then ({data}) ->
        data

    create: (entity) ->
      $http.post @endpoint, entity

    update: (projectId, entity) ->
      throw new Error('entity must have id') unless entity.id
      $http.put("#{endpoint}/#{entity.id}", entity)
