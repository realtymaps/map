app = require '../app.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.factory 'rmapsLoginFactory', (
$rootScope
$location
$log
$state
$uibModal
$http
rmapsPrincipalService
rmapsProfilesService
rmapsEventConstants
rmapsLoginHack
rmapsMapAuthorizationFactory
rmapsLoginService) ->

  $log = $log.spawn('rmapsLoginFactory')

  ($scope) ->

    $scope.loginInProgress = false
    $scope.showForm = !$rootScope.identity
    $scope.form =
      email: $location.search().email || ''
      loginToken: $location.search().loginToken || ''
      password: ''
      remember_me: false

    loginFailed = (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false
      $scope.loginFailed = true
      # $state.go 'login' #should already be in login state

    $scope.forgotPassword = () ->
      modalInstance = $uibModal.open
        scope: $scope
        template: require('../../html/views/templates/modals/passwordReset.jade')()

      modalInstance.result.then () ->
        $log.debug 'Sending password reset to', $scope.form.email
        $http.post backendRoutes.userSession.requestResetPassword, $scope.form
        .then (response) ->
          $log.debug response
          $scope.passwordResetSent = true
          $uibModal.open
            scope: $scope
            template: require('../../html/views/templates/modals/passwordReset.jade')()

    $scope.doLogin = (loginObj) ->
      loginObj ?= $scope.form
      # angular checkbox models don't interact well with lastpass, this fixes it
      loginObj.remember_me = document.querySelector('#remember_me')?.checked
      $scope.loginInProgress = true
      rmapsLoginService.login(loginObj)
      .then ({data, status}) ->

        if !httpStatus.isWithinOK status
          return loginFailed("Bad Status #{status}")
        if !data?.identity?
          return loginFailed("no identity")

        # setting user to $rootScope since this is where a reference to user is used in other parts of the app
        user = data.identity.user
        user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ''
        user.name = user.full_name or user.email
        $rootScope.user = user
        $rootScope.profiles = data.identity.profiles

        $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
        rmapsPrincipalService.setIdentity(data.identity)
        rmapsProfilesService.setCurrentProfileByIdentity data.identity
        .then () ->
          cb = () ->
            rmapsMapAuthorizationFactory.goToPostLoginState()
          rmapsLoginHack.checkLoggIn(cb)
          # Currently we can not go directly to login as the session is not synced
          # rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)
      .catch (response) ->
        loginFailed(response)

    return $scope
