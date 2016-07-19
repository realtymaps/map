app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.controller 'rmapsHeaderCtrl', (
  $scope,
  $log,
  rmapsEventConstants,
  rmapsProfilesService
) ->

  $scope.profile = rmapsProfilesService.currentProfile

  $scope.hasParentImage = () ->
    return $scope.profile?.parent_auth_user_id && $scope.profile.parent_image_id

  $scope.parentImageUrl = () ->
    if $scope.profile?.parent_auth_user_id && $scope.profile.parent_image_id
      backendRoutes.user.image.replace(':id', $scope.profile.parent_auth_user_id)

  $scope.$onRootScope rmapsEventConstants.principal.profile.updated, (newProfile) ->
    $scope.profile = newProfile
