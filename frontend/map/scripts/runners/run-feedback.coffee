_ = require 'lodash'
app = require '../app.coffee'

app.run (
  $rootScope
  $uibModal
  $q
  $log
  rmapsMainOptions
  rmapsUserSessionHistoryService
  rmapsUserFeedbackCategoryService
  rmapsUserFeedbackSubcategoryService
) ->
  $log = $log.spawn('run-feedback')

  createFeedbackModal = (feedback = {}) ->
    modalScope = $rootScope.$new false

    #BEGIN FEEDBACK
    $q.all(
      categories: rmapsUserFeedbackCategoryService.get()
      subcategories: rmapsUserFeedbackSubcategoryService.get())
    .then (results) ->
      results.categories = _.reject(results.categories, {id: 'deactivation'})
      _.extend(modalScope, results)

    modalScope.categoryChange = (cat) ->
      if !cat?
        return false

      modalScope.hasSubcat = _.some modalScope.subcategories, (sub) ->
        sub.category == cat.id

    modalScope.hasSubcat = false


    feedback.isEdit = !!feedback.description

    $uibModal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: require("../../html/views/templates/modals/feedbackModal.jade")()
      scope: modalScope
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> feedback

    .result.then (model) ->
      toSave = {
        category: model.category.id
        subcategory: model.subcategory.id
        description: model.description
      }

      if feedback.id? #update?
        toSave.id = feedback.id

      rmapsUserSessionHistoryService.save(toSave)

  $rootScope.giveFeedback = () ->
    createFeedbackModal()
