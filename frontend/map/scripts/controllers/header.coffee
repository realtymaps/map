app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.controller 'rmapsHeaderCtrl', (
  $rootScope,
  $scope,
  $log,
  rmapsEventConstants,
  rmapsPageService,
  rmapsPrincipalService,
  rmapsProfilesService
) ->

  $scope.getProfile = () ->
    rmapsProfilesService.currentProfile

  $scope.mobileHeaderType = () ->

    # Custom header controlled by child view
    if rmapsPageService.showMobileCustomHeader()
      return "CUSTOM"

    # Mobile modal header defined by route with buttons defined by child view
    if rmapsPageService.showMobileModalHeader()
      return "MODAL"

    # Viewer (sub-user) header
    if rmapsPrincipalService.isAuthenticated() && rmapsPrincipalService.isProjectViewer()
      return "VIEWER"

    return "OWNER"

  $scope.hasParentImage = () ->
    return $scope.getProfile()?.parent_auth_user_id && $scope.getProfile().parent_image_id

  $scope.parentImageUrl = () ->
    if $scope.getProfile()?.parent_auth_user_id && $scope.getProfile().parent_image_id
      backendRoutes.user.image.replace(':id', $scope.getProfile().parent_auth_user_id)


  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (newProfile) ->
    $scope.profile = newProfile
