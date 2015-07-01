app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsProfilesCtrl', ($scope, $location, Restangular, rmapsprincipal) ->
  rmapsprincipal.getIdentity()
  .then (identity) ->
    currentProfileSvc = Restangular.all(backendRoutes.user.currentProfile)

    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ""
    user.name = user.full_name or user.username
    _.extend $scope,
      user: user
      profiles: profiles
      select: (profile) ->
        currentProfileSvc.post(currentProfileId: profile.id)
        $location.path(frontendRoutes.map)
