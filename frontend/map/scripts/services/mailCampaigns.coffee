# app = require '../app.coffee'
# backendRoutes = require '../../../../common/config/routes.backend.coffee'

# app.service 'rmapsMailCampaignService', [ '$log', '$', ($log, Restangular) ->

#   mailAPI = backendRoutes.mail.apiBaseMailCampaigns

#   getMailCampaigns = (params = {}) ->
#     Restangular.all(mailAPI).getList(params)

#   getMailCampaign = (id) ->
#     Restangular.all(mailAPI).one(id).get()

#   postMailCampaign = (id, data) ->
#     Restangular.all(mlsConfigAPI).one(id).customPUT(data)






app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.factory 'rmapsMailCampaignService', ($log, $http) ->

  mailAPI = backendRoutes.mail.apiBaseMailCampaigns

  getList: () ->
    $http.get mailAPI, cache: false
    .then ({data}) ->
      data

  create: (entity) ->
    $http.post mailAPI, entity

  remove: (id) ->
    throw new Error('must have id') unless id
    id = '/' + id if id
    $http.delete(mailAPI + id)

  update: (entity) ->
    throw new Error('entity must have id') unless entity.id
    id = '/' + entity.id
    $http.put(mailAPI + id, entity)
