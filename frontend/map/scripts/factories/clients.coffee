app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.factory 'rmapsClientsFactory', ($http, $rootScope) ->

  class Clients
    constructor: (@projectId) ->
      @endpoint = "#{backendRoutes.projectSession.root}/#{@projectId}/clients"

    getAll: (query) ->
      $http.get @endpoint, cache: false, params: query
      .then ({data}) ->
        _.filter data, (d) ->
          isNotCurrent = d.id != $rootScope.principal.getCurrentProfileId()
          # if we are a project owner we might want to allow other owners to be shown
          # this would probably be another constructor option
          hasParent = !!d.parent_auth_user_id
          isNotCurrent && hasParent

    create: (entity) ->
      $http.post @endpoint, entity

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      $http.put "#{@endpoint}/#{entity.id}", entity
    remove: (entity) ->
      $http.delete "#{@endpoint}/#{entity.id}"
