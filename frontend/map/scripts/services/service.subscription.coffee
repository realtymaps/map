app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
subscriptionAPI = backendRoutes.user_subscription

app.service 'rmapsSubscriptionService', ($http, $sce) ->
  getPlan: () ->
    $http.get subscriptionAPI.getPlan, cache: false
    .then ({data}) ->
      data

  updatePlan: (plan) ->
    $http.put subscriptionAPI.updatePlan.replace(':plan', plan)
    .then ({data}) ->
      data

  reactivate: () ->
    $http.put subscriptionAPI.reactivate
    .then ({data}) ->
      data

  getSubscription: () ->
    $http.get subscriptionAPI.getSubscription, cache: false
    .then ({data}) ->
      data
    .catch (err) ->
      return error: $sce.trustAsHtml(err.data.alert.msg)

  deactivate: (info) ->
    $http.put subscriptionAPI.deactivate, info
    .then ({data}) ->
      data
