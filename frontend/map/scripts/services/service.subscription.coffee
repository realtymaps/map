app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
planAPI = backendRoutes.plans.apiBase
subscriptionAPI = backendRoutes.user_subscription

app.service 'rmapsSubscriptionService', ($http, $sce) ->
  getPlan: () ->
    $http.get subscriptionAPI.getPlan, cache: false
    .then ({data}) ->
      data

  setPlan: (plan) ->
    $http.put subscriptionAPI.setPlan.replace(':plan', plan)
    .then ({data}) ->
      data

  getSubscription: () ->
    $http.get subscriptionAPI.getSubscription, cache: false
    .then ({data}) ->
      data
    .catch (err) ->
      return error: $sce.trustAsHtml(err.data.alert.msg)

  deactivate: () ->
    $http.put subscriptionAPI.deactivate
    .then ({data}) ->
      data
