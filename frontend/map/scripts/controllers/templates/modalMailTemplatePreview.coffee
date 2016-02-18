app = require '../../app.coffee'


app.controller 'rmapsMailTemplateIFramePreviewCtrl',
  ($scope, $modalInstance, $log, $window, $timeout, template, rmapsMailTemplateService, rmapsMailTemplateTypeService) ->
    $scope.template = template
    $scope.mediaType = 'iframe'
    $timeout () ->
      $window.document.getElementById('mail-preview-iframe').srcdoc = rmapsMailTemplateService.createPreviewHtml(template.content)

    $scope.close = () ->
      $modalInstance.dismiss()


app.controller 'rmapsMailTemplatePdfPreviewCtrl',
  ($scope, $modalInstance, $log, $window, $timeout, $sce, template, rmapsMailTemplateService, rmapsLobService) ->
    $scope.template = template
    $scope.mediaType = 'pdf'
    $scope.processing = true
    rmapsLobService.getPdf(rmapsMailTemplateService.getLobData())
    .then (pdf) ->
      $scope.template.pdf = $sce.trustAsResourceUrl(pdf)
      $scope.processing = false

    $scope.close = () ->
      $modalInstance.dismiss()
