app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.service 'rmapsMailCampaignService', ($log, $http) ->
  $log = $log.spawn 'mail:mailCampaignService'
  mailAPI = backendRoutes.mail.apiBaseMailCampaigns

  get: (query) ->
    $log.debug "GET query:\n#{JSON.stringify query}"
    $http.get mailAPI, cache: false, params: query
    .then ({data}) ->
      data

  create: (entity) ->
    $log.debug -> "CREATE entity:\n#{JSON.stringify entity}"
    $http.post mailAPI, entity

  remove: (id) ->
    throw new Error('must have id') unless id
    id = '/' + id if id
    $http.delete(mailAPI + id)

  update: (entity) ->
    throw new Error('entity must have id') unless entity.id
    id = '/' + entity.id
    $http.put(mailAPI + id, entity)
