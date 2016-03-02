app = require '../../app.coffee'
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
  $scope.oldTemplateType = ""
  $scope.sentFile = false

  $scope.uploadFile = (file, errFiles) ->
    console.log "got a file!"

    $scope.f = file
    $scope.errFile = errFiles && errFiles[0]
    key = "uploads/#{(new Date()).getTime().toString(36)}_#{Math.floor(Math.random()*1000000).toString(36)}.pdf"

    console.log "s3_upload creds:"
    console.log "#{JSON.stringify(rmapsMainOptions.mail.s3_upload, null, 2)}"
    console.log "key: #{key}"

    if (file)
      file.upload = Upload.upload(
        url: 'https://rmaps-pdf-uploads.s3.amazonaws.com'
        method: 'POST'
        #data: {data: file}
        data:
          key: key
          AWSAccessKeyId: rmapsMainOptions.mail.s3_upload.AWSAccessKeyId
          acl: 'private'
          policy: rmapsMainOptions.mail.s3_upload.policy
          signature: rmapsMainOptions.mail.s3_upload.signature
          'Content-Type': 'application/pdf'
          #filename: file.name
          file: file
      )

      file.upload.then (response) ->
        $timeout () ->
          file.result = response.data
          $scope.wizard.mail.campaign.aws_key = key
          $scope.wizard.mail.save()
          $scope.sentFile = true
          console.log "sentfile turned ON"

          $timeout () ->
            $scope.sentFile = false
            file.progress = -1
            console.log "sentfile turned OFF"
          , 4000

      , (response) ->
        if (response.status > 0)
          $scope.errorMsg = response.status + ': ' + response.data

      , (evt) ->
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

  $rootScope.registerScopeData () ->
    $scope.ready()
    .then () ->
      $scope.oldTemplateType = $scope.wizard.mail.campaign.template_type


app.controller 'rmapsConfirmCtrl',
  ($scope, modalBody, modalTitle) ->
    $scope.modalBody = modalBody
    $scope.modalTitle = modalTitle
    $scope.showCancelButton = true
    $scope.modalCancel = ->
      $scope.$close(false)
    $scope.modalOk = ->
      $scope.$close(true)

