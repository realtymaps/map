app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.onboarding

app.service 'rmapsOnboardingService', ($http) ->

  user:
    create: (entity) ->
      $http.post(apiBase.createUser, entity)

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(apiBase + id, entity)
