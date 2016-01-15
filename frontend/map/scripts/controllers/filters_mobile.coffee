app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersMobileCtrl', ($scope, $filter, $timeout, rmapsFilters, $log) ->

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFilters.values

  # Generate the steps array with $10k steps up to $1m then $250k steps after
  stepsA = (step for step in [0 .. 1000000] by 10000)
  stepsB = (step for step in [1250000 .. 10000000] by 250000)

  steps = stepsA.concat stepsB
  $scope.steps = steps

  $scope.priceSlider =
#    min: 0
#    max: steps.length - 1
    min: 25
    max: steps.length - 25
    options:
      floor: 0,
      ceil: 10000000
      stepsArray: steps
      hideLimitLabels: true

  $scope.translateStep = (index) ->
    value = $filter('number')(steps[index], 0)
    if index == steps.length - 1
      value += '+'

    return value

  $timeout () ->
    $scope.$broadcast 'rzSliderForceRender'
