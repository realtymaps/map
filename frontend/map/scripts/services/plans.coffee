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
      plan = data.plan
      if plan.current_period_end
        plan.current_period_end = new Date(plan.current_period_end * 1000).toLocaleDateString()
      plan.group_name = plan.id.charAt(0).toUpperCase() + plan.id.slice(1) + " Tier"
      plan
