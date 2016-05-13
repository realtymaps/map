app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

module.exports = app.controller 'rmapsClientEntryCtrl', ($rootScope, $scope, $log, $state,
rmapsClientEntryService, rmapsEventConstants, rmapsPrincipalService, rmapsProfilesService, rmapsMapAuthorizationFactory) ->
  $log = $log.spawn 'rmapsClientEntryCtrl'
  console.log "rmapsClientEntryCtrl()"
  console.log "params:\n#{JSON.stringify($state.params,null,2)}"

  $scope.login = () ->
    console.log "$scope.client:\n#{JSON.stringify($scope.client,null,2)}"
    $scope.loginInProgress = true
    rmapsClientEntryService.setPasswordAndBounce $scope.client
    #$http.post backendRoutes.clientEntry.bounceLogin, $scope.client
    .then ({data, status}) ->
      console.log "rmapsClientEntryService data"
      if !httpStatus.isWithinOK status
        $scope.loginInProgress = false
        return

      # setting user to $rootScope since this is where a reference to user is used in other parts of the app
      $rootScope.user = data.identity.user
      $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
      rmapsPrincipalService.setIdentity(data.identity)
      rmapsProfilesService.setCurrentProfileByIdentity data.identity
      .then () ->
        rmapsMapAuthorizationFactory.goToPostLoginState()
    , (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false


  rmapsClientEntryService.getClientEntry $state.params.key
  .then (data) ->
    console.log "rmapsClientEntryCtrl service call,  getClientEntry:\n#{JSON.stringify(data,null,2)}"
    $scope.client = data.client
    $scope.parent = data.parent
    $scope.project = data.project
  .catch (err) ->
    console.log "err:\n#{JSON.stringify(err,null,2)}"

