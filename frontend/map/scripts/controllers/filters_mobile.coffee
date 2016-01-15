app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersMobileCtrl', ($scope, $filter, $timeout, rmapsFilters, $log) ->
  MAX_PRICE = 10000000
  MAX_SIZE = 10000

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFilters.values

  # Generate the steps array with $10k steps up to $1m then $250k steps after
  stepsA = (step for step in [0 .. 1000000] by 10000)
  stepsB = (step for step in [1250000 .. MAX_PRICE] by 250000)

  steps = stepsA.concat stepsB
  $scope.steps = steps

  $scope.priceSlider =
    min: 0
    max: steps.length - 1
    options:
      floor: 0,
      ceil: MAX_PRICE
      stepsArray: steps
      hideLimitLabels: true

  $scope.sizeSlider =
    min: 0
    max: MAX_SIZE
    options:
      floor: 0,
      ceil: MAX_SIZE
      step: 50
      hideLimitLabels: true

  $scope.translatePrice = (index) ->
    value = $filter('number')(steps[index], 0)
    if index == steps.length - 1
      value += '+'

    return value

  $scope.translateSize = (value) ->
    formatted = $filter('number')(value, 0)
    if value == MAX_SIZE
      formatted += '+'

    return formatted

  $timeout () ->
    $scope.$broadcast 'rzSliderForceRender'
