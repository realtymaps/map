app = require '../../app.coffee'


app.controller 'rmapsMailTemplateIFramePreviewCtrl', (
  $scope,
  $modalInstance,
  $log,
  $window,
  $timeout,template
) ->
  $scope.template = template
  $scope.mediaType = 'iframe'
  $timeout () ->
    $window.document.getElementById('mail-preview-iframe').srcdoc = $scope.template.content

  $scope.close = () ->
    $modalInstance.dismiss()


app.controller 'rmapsMailTemplatePdfPreviewCtrl', (
  $scope,
  $modalInstance,
  $log,
  $sce,
  template,
  rmapsMailCampaignService
) ->
  $scope.template = template
  $scope.mediaType = 'pdf'
  $scope.processing = true
  template.pdfPromise
  .then ({pdf}) ->
    $scope.template.pdf = $sce.trustAsResourceUrl(pdf)
    $scope.processing = false

  $scope.close = () ->
    $modalInstance.dismiss()


app.controller 'rmapsUploadedPdfPreviewCtrl', (
  $scope,
  $modalInstance,
  $log,
  $sce,
  template,
  rmapsMailPdfService
) ->
  $scope.template = template
  $scope.mediaType = 'pdf'
  $scope.processing = true
  rmapsMailPdfService.getSignedUrl template.content
  .then (url) ->
    $scope.template.pdf = $sce.trustAsResourceUrl(url)
    $scope.processing = false

  $scope.close = () ->
    $modalInstance.dismiss()


app.controller 'rmapsReviewPreviewCtrl', (
  $scope,
  $modalInstance,
  $log,
  $sce,
  wizard
) ->
  $scope.template = {}
  $scope.wizard = wizard
  $scope.mediaType = 'pdf'
  $scope.template.pdf = $sce.trustAsResourceUrl($scope.wizard.mail.review.pdf)

  $scope.close = () ->
    $modalInstance.dismiss()
