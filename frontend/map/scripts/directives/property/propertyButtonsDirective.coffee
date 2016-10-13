###globals angular###
app = require '../../app.coffee'

#
# USAGE:
#
#   The property and project should be passed in using directive attributes:
#
#      <property-buttons project="projectScopeVar" property="propertyScopeVar" ... ></property-buttons>
#
#   Or the JADE equivalent:
#
#      property-buttons(project="projectScopeVar" property="propertyScopeVar")
#
#   If a project is not defined, the currently selected project will be used
#
app.directive 'propertyButtons', (
  $log
  $rootScope,
  $state,
  rmapsEventConstants,
  rmapsProfilesService,
  rmapsPropertiesService,
  rmapsPropertyFormatterService,
  rmapsResultsFormatterService,
  rmapsMailCampaignService,
  $uibModal
) ->
#  $log.debug "Property Buttons directive: ", template
  return {
    restrict: 'EA'
    scope:
      propertyParent: '=property'
      projectParent: '=?project'
      zoomClick: '&?'
      pinClick: '&?'
      favoriteClick: '&?'
    templateUrl: './includes/directives/property/_propertyButtonsDirective.jade'
    controller: ($scope) ->
#      $log.debug "PROPERTY BUTTONS with property", $scope.propertyParent, "and project", $scope.projectParent

      # Only create the formatters at this level if they aren't already in the parent scope
      if $scope.$parent.formatters
        $scope.formatters = $scope.$parent.formatters

        if !$scope.formatters.results
          $scope.formatters.results = new rmapsResultsFormatterService  scope: $scope

        if !$scope.formatters.property
          $scope.formatters.property = rmapsPropertyFormatterService
      else
        $scope.formatters = {
          results: new rmapsResultsFormatterService  scope: $scope
          property: rmapsPropertyFormatterService
        }

      # Copy the parent project so that it can't be accidently changed by directive code
      if $scope.propertyParent
        $scope.property = angular.copy($scope.propertyParent)
      else
        $log.warn("Property Buttons Directive is not passed a Property argument")

      $scope.$watchCollection "propertyParent", (newValue) ->
        $scope.property = newValue

      if !$scope.projectParent
        $scope.project = angular.copy(rmapsProfilesService.currentProfile)
      else
        $scope.project = angular.copy($scope.projectParent)

      $scope.$watch "projectParent", (newValue) ->
        $scope.project = newValue

      $scope.zoomTo = ($event) ->
        $event.stopPropagation() if $event

        proceed = true
        if $scope.zoomClick
          proceed = $scope.zoomClick { property: $scope.property }

        if proceed
          $rootScope.$emit rmapsEventConstants.map.zoomToProperty, $scope.property

      $scope.pin = ($event) ->
        $event.stopPropagation() if $event

        proceed = true
        if $scope.pinClick
          proceed = $scope.pinClick { property: $scope.property }

        if proceed
          rmapsPropertiesService.pinUnpinProperty($scope.property)

      $scope.favorite = ($event) ->
        $event.stopPropagation() if $event

        proceed = true
        if $scope.favoriteClick
          proceed = $scope.favoriteClick { property: $scope.property }

        if proceed
          rmapsPropertiesService.favoriteProperty($scope.property)

      $scope.getMail = (property) ->
        if property?
          rmapsMailCampaignService.getMail(property.rm_property_id)

      $scope.addMail = (property) ->
        $scope.property = property
        $scope.newMail =
          property_ids: [property.rm_property_id]

        modalInstance = $uibModal.open
          scope: $scope
          template: require('../../../html/views/templates/modals/modal-mailHistory.jade')()

      rmapsMailCampaignService.getProjectMail()
  }
