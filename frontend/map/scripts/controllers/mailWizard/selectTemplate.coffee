app = require '../../app.coffee'
commonConfig = require '../../../../../common/config/commonConfig.coffee'
_ = require 'lodash'
confirmModalTemplate = require('../../../html/views/templates/modals/confirm.jade')()
previewModalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($rootScope, $scope, $log, $modal, $timeout, Upload,
  rmapsMailTemplateTypeService, rmapsMailTemplateFactory, rmapsMainOptions, rmapsMailPdfService) ->

  $log = $log.spawn 'mail:rmapsSelectTemplateCtrl'
  $log.debug 'rmapsSelectTemplateCtrl'

  $scope.displayCategory = 'all'
  $scope.categories = rmapsMailTemplateTypeService.getCategories()
  $scope.categoryLists = rmapsMailTemplateTypeService.getCategoryLists()
  $scope.oldTemplateType = $scope.wizard.mail.campaign.template_type
  $scope.sentFile = false
  $scope.uploadfile = null

  $scope.uploadFile = (file, errFiles) ->
    confirmTemplateChange()
    .then (result) ->
      if !result or !file
        $scope.uploadfile = null
        return
      $scope.f = file
      $scope.errFile = errFiles && errFiles[0]
      key = commonConfig.pdfUpload.getKey()

      file.upload = Upload.upload(
        url: rmapsMainOptions.mail.s3_upload.host
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
        console.log "response:"
        console.log response

        $timeout () ->
          file.result = response.data

          # create the new item to add to our categories
          newPdfItem =
            name: file.name.replace(/\.[^/.]+$/, "")
            thumb: '/assets/base/template_pdf_img.png'
            category: 'pdf'
            type: key

          # create and save new pdf model
          rmapsMailPdfService.create
            aws_key: key
            filename: newPdfItem.name
            last_used_mail_campaign_id: $scope.wizard.mail.campaign.id

          # add to category
          rmapsMailTemplateTypeService.appendCategoryList 'pdf', [newPdfItem]

          # select the item and update our campaign
          $scope.wizard.mail.setTemplateType(key)
          $scope.wizard.mail.save()
          $scope.oldTemplateType = $scope.wizard.mail.campaign.templateType

          # open preview
          $scope.previewTemplate newPdfItem

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

  confirmTemplateChange = () ->
    modalInstance = $modal.open
      animation: true
      template: confirmModalTemplate
      controller: 'rmapsConfirmCtrl'
      resolve:
        modalTitle: () ->
          return "Confirm template change"
        modalBody: () ->
          return "Selecting a different template or PDF will reset your letter content. Are you sure you wish to continue?"

    modalInstance.result.then (result) ->
      $log.debug "Confirmation result: #{result}"
      result

  $scope.selectTemplate = (idx) ->
    templateType = $scope.categoryLists[$scope.displayCategory][idx].type
    $log.debug "Selected template type: #{templateType}"
    $log.debug "Old template type: #{$scope.oldTemplateType}"
    $log.debug "Current campaign template type: #{$scope.wizard.mail.campaign.template_type}"

    if $scope.oldTemplateType != "" and $scope.oldTemplateType != templateType
      confirmTemplateChange(templateType)
      .then (result) ->
        if !result
          return
        $scope.wizard.mail.setTemplateType(templateType)
        $scope.oldTemplateType = $scope.wizard.mail.campaign.templateType

    else
      $scope.wizard.mail.setTemplateType(templateType)

  $scope.previewTemplate = (template) ->
    modalInstance = $modal.open
      template: previewModalTemplate
      controller: if template.category == 'pdf' then 'rmapsUploadedPdfPreviewCtrl' else 'rmapsMailTemplateIFramePreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          content: rmapsMailTemplateTypeService.getMailContent(template.type)
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

