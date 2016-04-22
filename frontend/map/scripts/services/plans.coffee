app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
planAPI = backendRoutes.plans.apiBase
subscriptionAPI = backendRoutes.user_subscription

app.service 'rmapsPlansService', ($http) ->
  getList: () ->
    $http.get planAPI, cache: true
    .then ({data}) ->
      data

  getPlan: () ->
    $http.get subscriptionAPI.getPlan, cache: false
    .then ({data}) ->
      data

  setPlan: (plan) ->
    $http.put subscriptionAPI.setPlan.replace(':plan', plan)
    .then ({data}) ->
      data

  deactivate: () ->
    $http.put subscriptionAPI.deactivate
    .then ({data}) ->
      data
