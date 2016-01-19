app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersMobileCtrl', ($scope, $filter, $timeout, rmapsFilters, $log) ->
  MAX_PRICE = 10000000
  MAX_SIZE = 10000
  MAX_DOM = 365

  console.log "Selected Filters !!! #{$scope.selectedFilters}"

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFilters.values

  # Initialize scope values from the global filters
  $scope.bedsMin = $scope.selectedFilters.bedsMin || 0
  $scope.bathsMin = $scope.selectedFilters.bathsMin || 0

  # Create slider options


  # Generate the steps array with $10k steps up to $1m then $250k steps after
  stepsA = (step for step in [0 .. 1000000] by 10000)
  stepsB = (step for step in [1250000 .. MAX_PRICE] by 250000)

  steps = stepsA.concat stepsB
  $scope.steps = steps

  #
  # Set up price slider and use previously set min/max values
  #
  priceMin = $scope.selectedFilters.priceMin
  if priceMin
    priceMin = 1 * priceMin.replace(/[$,]/g, '')
  else
    priceMin = 0

  priceMax = $scope.selectedFilters.priceMax
  if priceMax
    priceMax = 1 * priceMax.replace(/[$,]/g, '')
  else
    priceMax = MAX_PRICE

  stepMin = 0
  stepMinIdx = 0
  stepMax = -1
  stepMaxIdx = -1
  for step, idx in steps
    if step <= priceMin
      stepMin = step
      stepMinIdx = idx

    if step >= priceMax and stepMax == -1
      stepMax = step
      stepMaxIdx = idx

  stepMaxIdx = steps.length - 1 if stepMax == -1

  $scope.priceSlider =
    min: stepMinIdx
    max: stepMaxIdx
    options:
      floor: 0,
      ceil: MAX_PRICE
      stepsArray: steps
      hideLimitLabels: true

  #
  # Set up Size slider and use any previously set min/max values
  #
  sizeMin = $scope.selectedFilters.sizeMin
  if sizeMin
    sizeMin = 1 * sizeMin.replace(/[$,]/g, '')
  else
    sizeMin = 0

  sizeMax = $scope.selectedFilters.sizeMax
  if sizeMax
    sizeMax = 1 * sizeMax.replace(/[$,]/g, '')
  else
    sizeMax = MAX_SIZE

  $scope.sizeSlider =
    min: 0
    max: MAX_SIZE
    options:
      floor: 0,
      ceil: MAX_SIZE
      step: 50
      hideLimitLabels: true

  $scope.domSlider =
    min: 0
    max: MAX_DOM
    options:
      floor: 0,
      ceil: MAX_DOM
      step: 1
      hideLimitLabels: true

  $timeout () ->
    $scope.$broadcast 'rzSliderForceRender'

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

  $scope.translateDom = (value) ->
    formatted = $filter('number')(value, 0)
    if value == MAX_DOM
      formatted += '+'

    return formatted

  #
  # Events
  #

  $scope.changeBeds = (incr) ->
    $scope.bedsMin = $scope.bedsMin + incr
    $scope.bedsMin = 0 if $scope.bedsMin < 0

  $scope.changeBaths = (incr) ->
    $scope.bathsMin = $scope.bathsMin + incr
    $scope.bathsMin = 0 if $scope.bathsMin < 0

  # Options for the price slider
  $scope.apply = () ->
    $log.debug "Apply changes"
    $scope.selectedFilters.priceMin = "" + steps[$scope.priceSlider.min]
    $scope.selectedFilters.priceMax = "" + steps[$scope.priceSlider.max]
    $scope.selectedFilters.bedsMin = $scope.bedsMin
    $scope.selectedFilters.bathsMin = $scope.bathsMin

    $scope.close()

