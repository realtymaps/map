app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersCtrl', ($scope, $timeout, rmapsFiltersFactory) ->

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFiltersFactory.values

  MIN_BEDS = 1
  MAX_BEDS = 10
  MIN_BATHS = 0.5
  MAX_BATHS = 10

  $scope.bedsSlider = options: floor: MIN_BEDS, ceil: MAX_BEDS, step: MIN_BEDS
  $scope.bathsSlider = options: floor: MIN_BATHS, ceil: MAX_BATHS, step: MIN_BATHS, precision: 1

  $timeout (() ->
    $scope.$broadcast 'reCalcViewDimensions'
    $timeout (() ->
      $scope.$broadcast 'rzSliderForceRender'
      , 10)
    , 10)
