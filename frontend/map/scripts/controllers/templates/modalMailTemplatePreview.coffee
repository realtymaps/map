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
    rmapsLobService.getPdf($scope.template.lobData)
    .then (pdf) ->
      $scope.template.pdf = $sce.trustAsResourceUrl(pdf)
      $scope.processing = false

    $scope.close = () ->
      $modalInstance.dismiss()
