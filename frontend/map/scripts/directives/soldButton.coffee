app = require '../app.coffee'

app.directive 'rmapsSoldButton', ($rootScope, $log, $compile, rmapsFiltersFactory) ->
  $log = $log.spawn 'rmapsSoldButton'
  restrict: 'AE'
  scope:
    filters: '='
    top: '='

  templateUrl: './includes/directives/soldButton.jade'
  controller: ($scope, $element, $attrs, $transclude) ->
    $log.debug $element

    if $attrs.menu == 'top'
      $scope.menuTop = true

    $scope.options = rmapsFiltersFactory.values.soldRangeValues

    setSelected = () ->
      $scope.selected = _.find($scope.options, 'value', $scope.filters.soldRange)

    $scope.$watch 'filters.soldRange', setSelected

    $scope.shortName = (option) ->
      option.value.match(/\d+ \w/)?[0] || option.value

    $scope.onClick = (option) ->
      $scope.filters.soldRange = option.value
      $scope.isOpen = false
