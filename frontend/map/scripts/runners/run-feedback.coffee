_ = require 'lodash'
app = require '../app.coffee'

app.run (
$rootScope, $uibModal, $q,
rmapsMainOptions
rmapsUserSessionHistoryService
rmapsHistoryUserCategoryService
rmapsHistoryUserSubCategoryService) ->

  #BEGIN FEEDBACK
  $q.all(
    categories: rmapsHistoryUserCategoryService.get()
    subCategories: rmapsHistoryUserSubCategoryService.get())
  .then (results) ->
    _.extend($rootScope, results)

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
