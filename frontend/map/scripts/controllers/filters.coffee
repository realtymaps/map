app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersCtrl', ($scope, $timeout, $log, rmapsFiltersFactory) ->

  $log = $log.spawn 'rmapsFiltersCtrl'

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFiltersFactory.values

  MIN_BEDS = 0
  MAX_BEDS = 10
  MIN_BATHS = 0
  MAX_BATHS = 6

  $scope.bedsSlider = options: floor: MIN_BEDS, ceil: MAX_BEDS, step: 1
  $scope.bathsSlider = options: floor: MIN_BATHS, ceil: MAX_BATHS, step: 0.5, precision: 1

  $scope.reset = ->
    $log.debug 'reset'
    $scope.selectedFilters.bedsMin = MIN_BEDS
    $scope.selectedFilters.bathsMin = MIN_BATHS
    $scope.selectedFilters.priceMin = null
    $scope.selectedFilters.priceMax = null
    $scope.selectedFilters.sqftMin = null
    $scope.selectedFilters.sqftMax = null
    $scope.selectedFilters.acresMin = null
    $scope.selectedFilters.acresMax = null
    $scope.selectedFilters.listedDaysMin = null
    $scope.selectedFilters.listedDaysMax = null
    $scope.selectedFilters.closePriceMin = null
    $scope.selectedFilters.closePriceMax = null
    $scope.selectedFilters.ownerName = null

  $scope.toggled = ->
    $log.debug 'forceRender'
    $timeout (->
      $scope.$broadcast 'reCalcViewDimensions'
      $timeout (->
        $scope.$broadcast 'rzSliderForceRender'
      ), 10
    ), 10

