_ = require 'lodash'
app = require '../app.coffee'

app.run (
$rootScope, $uibModal, $q, $log,
rmapsMainOptions
rmapsUserSessionHistoryService
rmapsHistoryUserCategoryService
rmapsHistoryUserSubCategoryService) ->
  $log = $log.spawn('run-feedback')

  createFeedbackModal = (feedback = {}) ->
    modalScope = $rootScope.$new false

    #BEGIN FEEDBACK
    $q.all(
      categories: rmapsHistoryUserCategoryService.get()
      subCategories: rmapsHistoryUserSubCategoryService.get())
    .then (results) ->
      _.extend(modalScope, results)

    modalScope.categoryChange = (cat) ->
      if !cat?
        return false

      modalScope.hasSubCat = _.some modalScope.subCategories, (sub) ->
        sub.category_id == cat.id

    modalScope.hasSubCat = false


    feedback.isEdit = !!feedback.description

    $uibModal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: require("../../html/views/templates/modals/feedbackModal.jade")()
      scope: modalScope
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> feedback

    .result.then (model) ->
      toSave = {
        category_id: model.category.id
        subcategory_id: model.subcategory.id
        description: model.description
      }

      if feedback.id? #update?
        toSave.id = feedback.id

      rmapsUserSessionHistoryService.save(toSave)

  $rootScope.giveFeedback = () ->
    createFeedbackModal()
