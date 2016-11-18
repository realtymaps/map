_ = require 'lodash'
app = require '../app.coffee'

###
  Our Filters Controller
###
module.exports = app.controller 'rmapsFiltersCtrl', (
$scope
$timeout
$log
rmapsFiltersFactory
) ->

  $log = $log.spawn 'rmapsFiltersCtrl'

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFiltersFactory.values

  $scope.bedsSlider = options: floor: rmapsFiltersFactory.MIN_BEDS, ceil: rmapsFiltersFactory.MAX_BEDS, step: 1
  $scope.bathsSlider = options: floor: rmapsFiltersFactory.MIN_BATHS, ceil: rmapsFiltersFactory.MAX_BATHS, step: 0.5, precision: 1

  $scope.selectedFilters.bedsMin ?= rmapsFiltersFactory.MIN_BEDS
  $scope.selectedFilters.bathsMin ?= rmapsFiltersFactory.MIN_BATHS

  $scope.reset = ->
    $log.debug 'reset'
    _.extend $scope.selectedFilters, rmapsFiltersFactory.valueDefaults

  $scope.tooltipOpen = false
  $scope.toggled = () ->
    $scope.tooltipOpen = false
    $log.debug 'forceRender'
    $timeout (->
      $scope.$broadcast 'reCalcViewDimensions'
      $timeout (->
        $scope.$broadcast 'rzSliderForceRender'
      ), 10
    ), 10

  $scope.onChange = ->
    $log.debug $scope.selectedFilters

  $scope.datepickers = {}
  $scope.openDatepicker = (id) ->
    # close all the others, and open this one
    for key of $scope.datepickers
      $scope.datepickers[key] = false
    $scope.datepickers[id] = true
