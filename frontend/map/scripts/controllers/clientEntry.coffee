app = require '../app.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

module.exports = app.controller 'rmapsClientEntryCtrl', (
  $rootScope,
  $scope,
  $log,
  $state,
  #$http,
  rmapsClientEntryService,
  rmapsEventConstants,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsMapAuthorizationFactory,
  rmapsResponsiveViewService,
  rmapsLoginHack
) ->
  $log = $log.spawn 'rmapsClientEntryCtrl'

  mobileView = rmapsResponsiveViewService.isMobileView()

  $scope.login = () ->
    $scope.loginInProgress = true

    # based on login controller
    rmapsClientEntryService.setPasswordAndBounce $scope.client
    .then ({data, status}) ->
      if !httpStatus.isWithinOK status
        $scope.loginInProgress = false
        return

      # setting user to $rootScope since this is where a reference to user is used in other parts of the app
      $rootScope.user = data.identity.user
      $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
      rmapsPrincipalService.setIdentity(data.identity)
      rmapsProfilesService.setCurrentProfileByIdentity data.identity
      .then () ->
        cb = () ->
          if mobileView
            $state.go('project', {id: $scope.project.id}, {reload: true})
          else
            #$state.go('map', {id: $scope.project.id}, {reload: true})
            rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)

        rmapsLoginHack.checkLoggIn(cb)

    , (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false

  rmapsClientEntryService.getClientEntry $state.params.key
  .then (data) ->
    $scope.client = data.client
    $scope.parent = data.parent
    $scope.project = data.project
