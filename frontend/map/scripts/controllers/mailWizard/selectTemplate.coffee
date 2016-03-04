app = require '../../app.coffee'
commonConfig = require '../../../../../common/config/commonConfig.coffee'
_ = require 'lodash'
confirmModalTemplate = require('../../../html/views/templates/modals/confirm.jade')()
previewModalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($rootScope, $scope, $log, $modal, $timeout, Upload,
  rmapsMailTemplateTypeService, rmapsMailTemplateFactory, rmapsMainOptions) ->

  $log = $log.spawn 'mail:rmapsSelectTemplateCtrl'
  $log.debug 'rmapsSelectTemplateCtrl'

  $scope.displayCategory = 'all'
  $scope.categories = rmapsMailTemplateTypeService.getCategories()
  $scope.categoryLists = rmapsMailTemplateTypeService.getCategoryLists()
  $scope.oldTemplateType = $scope.wizard.mail.campaign.template_type
  $scope.sentFile = false

  $scope.uploadFile = (file, errFiles) ->
    $scope.f = file
    $scope.errFile = errFiles && errFiles[0]
    key = commonConfig.pdfUpload.getKey()

    if (file)
      file.upload = Upload.upload(
        url: 'https://rmaps-pdf-uploads.s3.amazonaws.com'
        method: 'POST'
        data:
          key: key
          AWSAccessKeyId: rmapsMainOptions.mail.s3_upload.AWSAccessKeyId
          acl: 'private'
          policy: rmapsMainOptions.mail.s3_upload.policy
          signature: rmapsMainOptions.mail.s3_upload.signature
          'Content-Type': 'application/pdf'
          file: file
      )

      file.upload.then (response) ->
        $timeout () ->
          file.result = response.data
          $scope.wizard.mail.campaign.aws_key = key
          $scope.wizard.mail.save()
          $scope.sentFile = true

          $timeout () ->
            $scope.sentFile = false
            file.progress = -1
          , 4000

      , (response) ->
        if (response.status > 0)
          $scope.errorMsg = response.status + ': ' + response.data

      , (evt) ->
        file.progress = Math.min(100, parseInt(100.0 * evt.loaded / evt.total))

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
    $log.debug "Current campaign template type: #{$scope.wizard.mail.campaign.template_type}"

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
          $scope.wizard.mail.setTemplateType(templateType)
          $scope.oldTemplateType = $scope.wizard.mail.campaign.templateType

    else
      $scope.wizard.mail.setTemplateType(templateType)

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

app.controller 'rmapsConfirmCtrl',
  ($scope, modalBody, modalTitle) ->
    $scope.modalBody = modalBody
    $scope.modalTitle = modalTitle
    $scope.showCancelButton = true
    $scope.modalCancel = ->
      $scope.$close(false)
    $scope.modalOk = ->
      $scope.$close(true)

