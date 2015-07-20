app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUserCtrl', ($scope, $rootScope, $location, $http, rmapsprincipal) ->
  rmapsprincipal.getIdentity()
  .then (identity) ->

    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ""
    user.name = user.full_name or user.username

    $http.get(backendRoutes.us_states.root)
    .then (data) ->
      $scope.us_states = data.data

    _.extend $scope,
      user: user
      profiles: profiles

      submit: ->
