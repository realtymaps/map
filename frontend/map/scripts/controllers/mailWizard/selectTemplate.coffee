app = require '../../app.coffee'
_ = require 'lodash'
confirmModalTemplate = require('../../../html/views/templates/modals/confirm.jade')()
previewModalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($rootScope, $scope, $log, $modal, $timeout, Upload, rmapsMailTemplateTypeService, rmapsMailTemplateService) ->
  $log = $log.spawn 'mail:rmapsSelectTemplateCtrl'
  $log.debug 'rmapsSelectTemplateCtrl'


  $scope.uploadFile = (file, errFiles) ->
    console.log "got a file!"
    $scope.f = file
    $scope.errFile = errFiles && errFiles[0]
    if (file)
      file.upload = Upload.upload(
        url: 'https://angular-file-upload-cors-srv.appspot.com/upload'
        data: {data: file}
      )

      file.upload.then (response) ->
        $timeout () ->
          file.result = response.data
          console.log "file result:"
          console.log file.result

      , (response) ->
        if (response.status > 0)
          $scope.errorMsg = response.status + ': ' + response.data
        console.log "error"
        console.log response
      , (evt) ->
        console.log "event!"
        console.log evt
        file.progress = Math.min(100, parseInt(100.0 * evt.loaded / evt.total))


    # $scope.fileSelected = (files) ->
    #   if (files && files.length)
    #     $scope.file = files[0]

    #   $upload.upload(
    #     url: 'http://localhost:8085/assets'
    #     file: $scope.file
    #   )
    #   .success (data) ->
    #     console.log data, 'uploaded'
   

  $scope.displayCategory = 'all'

  $scope.categories = rmapsMailTemplateTypeService.getCategories()
  $scope.categoryLists = rmapsMailTemplateTypeService.getCategoryLists()
  $scope.campaign = rmapsMailTemplateService.getCampaign()
  $scope.oldTemplateType = $scope.campaign.template_type
  

  $scope.isEmptyCategory = () ->
    return $scope.displayCategory not of $scope.categoryLists or $scope.categoryLists[$scope.displayCategory].length == 0

  $scope.setCategory = (category) ->
    if !category?
      category = 'all'
    $scope.displayCategory = category

  $scope.selectTemplate = (idx) ->
    templateType = $scope.categoryLists[$scope.displayCategory][idx].type
    $log.debug "Selected template type: #{templateType}"
    $log.debug "Old template type: #{$scope.oldTemplateType}"
    $log.debug "Current template type: #{$scope.campaign.template_type}"

    if $scope.oldTemplateType != "" and $scope.oldTemplateType != templateType
      modalInstance = $modal.open
        animation: true
        template: confirmModalTemplate
        controller: 'rmapsConfirmCtrl'
        resolve:
          modalTitle: () ->
            return "Confirm template change"
          modalBody: () ->
            return "Selecting a different template will reset your letter content. Are you sure you wish to continue?"

      modalInstance.result.then (result) ->
        $log.debug "Confirmation result: #{result}"
        if result
          rmapsMailTemplateService.setTemplateType(templateType)
          $scope.campaign = rmapsMailTemplateService.getCampaign()
          $scope.oldTemplateType = $scope.campaign.templateType

    else
      rmapsMailTemplateService.setTemplateType(templateType)

  $scope.previewTemplate = (template) ->
    modalInstance = $modal.open
      template: previewModalTemplate
      controller: 'rmapsMailTemplateIFramePreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          content: rmapsMailTemplateTypeService.getHtml(template.type)
          category: template.category
          title: template.name

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      $scope.campaign = rmapsMailTemplateService.getCampaign()
      $log.debug -> "Loaded campaign:\n#{JSON.stringify($scope.campaign, null, 2)}"
      $scope.oldTemplateType = $scope.campaign.template_type


app.controller 'rmapsConfirmCtrl',
  ($scope, modalBody, modalTitle) ->
    $scope.modalBody = modalBody
    $scope.modalTitle = modalTitle
    $scope.showCancelButton = true
    $scope.modalCancel = ->
      $scope.$close(false)
    $scope.modalOk = ->
      $scope.$close(true)

