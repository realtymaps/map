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

  $log = $log.spawn("rmapsHeaderCtrl")

  $scope.getProfile = () ->
    rmapsProfilesService.currentProfile

  $scope.desktopHeaderType = () ->
    # Viewer (sub-user) header
    if rmapsPrincipalService.isAuthenticated() && rmapsPrincipalService.isProjectViewer()
      return "VIEWER"

    return "OWNER"

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

  $scope.hasParentName = () ->
    return $scope.getProfile()?.parent_name?.trim().length > 0

  $scope.hasParentImage = () ->
    {parent_image_id, parent_auth_user_id} = $scope.getProfile()
    $log.debug -> {parent_image_id, parent_auth_user_id}

    return parent_auth_user_id? && parent_image_id?

  $scope.parentImageUrl = () ->
    if $scope.getProfile()?.parent_auth_user_id && $scope.getProfile().parent_image_id
      backendRoutes.user.image.replace(':id', $scope.getProfile().parent_auth_user_id)
