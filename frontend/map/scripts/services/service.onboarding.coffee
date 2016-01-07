app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

backendRoutes.stripe =
  apiBase: "api/stripe"

apiBase = backendRoutes.stripe.apiBase

app.service 'rmapsOnboardingService', ($http, $q) ->

  user:
    create: (entity) ->
      # $http.post(apiBase, entity)
      $q.resolve entity

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(apiBase + id, entity)
