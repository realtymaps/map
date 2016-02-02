app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.factory 'rmapsClientsFactory', ($http) ->

  class Clients
    constructor: (@projectId) ->
      @endpoint = "#{backendRoutes.projectSession.root}/#{@projectId}/clients"

    getAll: (query) ->
      $http.get @endpoint, cache: false, params: query
      .then ({data}) ->
        data

    create: (entity) ->
      $http.post @endpoint, entity

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      $http.put "#{@endpoint}/#{entity.id}", entity
    remove: (entity) ->
      $http.delete "#{@endpoint}/#{entity.id}"
