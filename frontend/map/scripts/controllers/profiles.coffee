app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsProfilesCtrl', ($scope, $rootScope, $location, $http, rmapsprincipal) ->
  rmapsprincipal.getIdentity()
  .then (identity) ->
    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ''
    user.name = user.full_name or user.username

    _.extend $scope,
      user: user
      profiles: profiles

      select: (profile, $event) ->
        $event.stopPropagation()
        #https://github.com/angular/angular.js/pull/10288
        return if profile.showProfileNameInput#needed for spaces in input name
        $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)
        .then ->
          rmapsprincipal.getCurrentProfile(profile.id)
        .then ->
          $location.path(frontendRoutes.map)

      change:(profile) ->
        profile.needsUpdate = true

      activateInput: (profile, $event) ->
        $event.stopPropagation()
        profile.showProfileNameInput = !profile.showProfileNameInput

      blur: ->
        anyToTurnOff = _.any $scope.profiles, (p) ->
          p.showProfileNameInput
        if anyToTurnOff
          $scope.$evalAsync ->
            for key, profile of $scope.profiles
              profile.showProfileNameInput = false
              if profile.needsUpdate
                $http.put(backendRoutes.userSession.profiles, _.omit profile, ['needToUpdate', 'showProfileNameInput'])
                .success ->
                  rmapsprincipal.unsetIdentity()

    $rootScope.$on 'rmapsRootClick', ->
      $scope.blur()
