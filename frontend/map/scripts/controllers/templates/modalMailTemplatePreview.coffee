app = require '../../app.coffee'


app.controller 'rmapsMailTemplateIFramePreviewCtrl',
  ($scope, $modalInstance, $log, $window, $timeout, template) ->
    $scope.template = template
    $scope.mediaType = 'iframe'
    $timeout () ->
      $window.document.getElementById('mail-preview-iframe').srcdoc = $scope.template.content

    $scope.close = () ->
      $modalInstance.dismiss()


app.controller 'rmapsMailTemplatePdfPreviewCtrl',
  ($scope, $modalInstance, $log, $sce, template, rmapsLobService) ->
    $scope.template = template
    $scope.mediaType = 'pdf'
    $scope.processing = true
    rmapsLobService.getPdf(template.campaign.id)
    .then (pdf) ->
      $scope.template.pdf = $sce.trustAsResourceUrl(pdf)
      $scope.processing = false

    $scope.close = () ->
      $modalInstance.dismiss()


app.controller 'rmapsUploadedPdfPreviewCtrl',
  ($scope, $modalInstance, $log, $sce, template, rmapsMailPdfService) ->
    $scope.template = template
    $scope.mediaType = 'pdf'
    $scope.processing = true
    rmapsMailPdfService.getSignedUrl template.content
    .then (url) ->
      $scope.template.pdf = $sce.trustAsResourceUrl(url)
      $scope.processing = false

    $scope.close = () ->
      $modalInstance.dismiss()


app.controller 'rmapsReviewPreviewCtrl',
  ($scope, $modalInstance, $log, $sce, template, rmapsLobService) ->
    console.log "rmapsReviewPreviewCtrl, template:\n#{JSON.stringify(template,null,2)}"
    $scope.template = template
    $scope.mediaType = 'pdf'
    $scope.template.pdf = $sce.trustAsResourceUrl($scope.template.pdf)

    $scope.close = () ->
      $modalInstance.dismiss()
