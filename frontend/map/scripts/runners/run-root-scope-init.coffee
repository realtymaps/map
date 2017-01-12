_ = require 'lodash'
app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

# there are some values we want to save onto the root scope
app.run (
$rootScope, $state, $stateParams, $timeout, $window, $uibModal,
rmapsPrincipalService
rmapsSpinnerService
rmapsEventConstants
rmapsPageService
rmapsMainOptions
rmapsUserSessionHistoryService) ->

  $rootScope.alerts = []
  $rootScope.adminRoutes = adminRoutes
  $rootScope.frontendRoutes = frontendRoutes
  $rootScope.backendRoutes = backendRoutes
  $rootScope.principal = rmapsPrincipalService
  # TODO: Chris' idea of adding profileService or currentProfile
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams
  $rootScope.Spinner = rmapsSpinnerService
  $rootScope.stateData = []
  $rootScope.page = rmapsPageService
  $rootScope._ = window._

  $rootScope.windowWidth = $window.innerWidth
  $rootScope.windowHeight = $window.innerHeight

  angular.element($window).bind 'resize', ->
    $rootScope.windowWidth = $window.innerWidth
    $rootScope.windowHeight = $window.innerHeight

  createFeedbackModal = (feedback = {}) ->
    modalScope = $rootScope.$new false

    feedback.isEdit = !!feedback.description

    $uibModal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: require("../../html/views/templates/modals/feedbackModal.jade")()
      scope: modalScope
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> feedback

    .result.then (model) ->
      rmapsUserSessionHistoryService.save(_.omit(model, 'isEdit'))

  $rootScope.giveFeedback = () ->
    createFeedbackModal()
