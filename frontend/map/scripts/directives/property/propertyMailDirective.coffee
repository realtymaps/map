###globals angular###
app = require '../../app.coffee'

app.directive 'propertyMail', (
  $log,
  rmapsMailCampaignService,
  rmapsProfilesService,
  $uibModal
) ->
  $log = $log.spawn 'propertyMail'
  return {
    restrict: 'EA'
    scope:
      propertyParent: '=property'
    templateUrl: './includes/directives/property/_propertyMailDirective.jade'
    controller: ($scope) ->

      if $scope.propertyParent
        $scope.property = angular.copy($scope.propertyParent)
      else
        $log.warn("Property Mail Directive is not passed a Property argument")

      $scope.$watchCollection "propertyParent", (newValue) ->
        $scope.property = newValue

      $scope.previewLetter = (mail) ->
        $uibModal.open
          template: require('../../../html/views/templates/modal-mailPreview.tpl.jade')()
          controller: 'rmapsReviewPreviewCtrl'
          openedClass: 'preview-mail-opened'
          windowClass: 'preview-mail-window'
          windowTopClass: 'preview-mail-windowTop'
          resolve:
            template: () ->
              pdf: "#{mail.lob.preview}/pdf"
              title: 'Mail Review'

      if $scope.property?
        rmapsMailCampaignService.getProjectMail()
        .then ->
          $scope.mailings = (rmapsMailCampaignService.getMail($scope.property.rm_property_id))?.mailings
  }
