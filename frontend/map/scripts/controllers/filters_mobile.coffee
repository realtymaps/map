app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersMobileCtrl', ($scope, $filter, $timeout, rmapsFilters, $log) ->
  MAX_PRICE = 10000000
  MAX_SIZE = 10000
  MAX_DOM = 365

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFilters.values

  # Initialize scope values from the global filters
  $scope.bedsMin = $scope.selectedFilters.bedsMin || 0
  $scope.bathsMin = $scope.selectedFilters.bathsMin || 0

  #
  # Create slider step arrays
  #
  initStepsArray = (minValue, maxValue, startIncrement, breakpoint, endIncrement) ->
    stepsA = (step for step in [minValue .. breakpoint] by startIncrement)
    stepsB = (step for step in [breakpoint + endIncrement .. maxValue] by endIncrement)

    stepsA.concat stepsB

  priceSteps = initStepsArray 0, MAX_PRICE, 10000, 1000000, 250000
  sizeSteps = initStepsArray 0, MAX_SIZE, 100, 5000, 500
  domSteps = initStepsArray 0, MAX_DOM, 1, 180, 5

  #
  # Create slider options
  #
  initSliderConfig = (minValue, maxValue, steps, presetMin, presetMax) ->
    # Filter the user filter values for $ and , characters
    if presetMin
      presetMin = 1 * presetMin.replace(/[$,]/g, '')
    else
      presetMin = minValue

    if presetMax
      presetMax = 1 * presetMax.replace(/[$,]/g, '')
    else
      presetMax = maxValue

    # Find the closest step values lower than the existing min and higher than the existing max
    stepMin = 0
    stepMinIdx = 0
    stepMax = -1
    stepMaxIdx = -1
    for step, idx in steps
      if step <= presetMin
        stepMin = step
        stepMinIdx = idx

      if step >= presetMax and stepMax == -1
        stepMax = step
        stepMaxIdx = idx

    stepMaxIdx = steps.length - 1 if stepMax == -1

    return {
      min: stepMinIdx
      max: stepMaxIdx
      options:
        floor: minValue,
        ceil: maxValue
        stepsArray: steps
        hideLimitLabels: true
    }

  $scope.priceSlider = initSliderConfig 0, MAX_PRICE, priceSteps, $scope.selectedFilters.priceMin, $scope.selectedFilters.priceMax
  $scope.sizeSlider = initSliderConfig 0, MAX_SIZE, sizeSteps, $scope.selectedFilters.sqftMin, $scope.selectedFilters.sqftMax
  $scope.domSlider = initSliderConfig 0, MAX_DOM, domSteps, $scope.selectedFilters.listedDaysMin, $scope.selectedFilters.listedDaysMax

  $timeout () ->
    $scope.$broadcast 'rzSliderForceRender'

  #
  # Display step value to user
  #

  $scope.translatePrice = (index) ->
    value = $filter('number')(priceSteps[index], 0)
    if index == priceSteps.length - 1
      value += '+'

    return value

  $scope.translateSize = (index) ->
    value = $filter('number')(sizeSteps[index], 0)
    if index == sizeSteps.length - 1
      value += '+'

    return value

  $scope.translateDom = (index) ->
    value = $filter('number')(domSteps[index], 0)
    if index == domSteps.length - 1
      value += '+'

    return value

  $scope.translateNumeric = (value) ->
    return (value || "0") + "+"

  #
  # Events
  #

  $scope.changeBeds = (incr) ->
    $scope.bedsMin = $scope.bedsMin + incr
    $scope.bedsMin = 0 if $scope.bedsMin < 0

  $scope.changeBaths = (incr) ->
    $scope.bathsMin = $scope.bathsMin + incr
    $scope.bathsMin = 0 if $scope.bathsMin < 0

  #
  # Apply the filter changes to the map results
  #
  $scope.apply = () ->
    # If the slider has been set at the maximum value,
    # delete the current filter max so the filter will not have an upper bound

    $scope.selectedFilters.priceMin = "" + priceSteps[$scope.priceSlider.min]
    if $scope.priceSlider.max < priceSteps.length - 1
      $scope.selectedFilters.priceMax = "" + priceSteps[$scope.priceSlider.max]
    else
      delete $scope.selectedFilters.priceMax

    $scope.selectedFilters.sqftMin = "" + sizeSteps[$scope.sizeSlider.min]
    if $scope.sizeSlider.max < sizeSteps.length - 1
      $scope.selectedFilters.sqftMax = "" + sizeSteps[$scope.sizeSlider.max]
    else
      delete $scope.selectedFilters.sqftMax

    $scope.selectedFilters.listedDaysMin = "" + domSteps[$scope.domSlider.min]
    if $scope.domSlider.max < domSteps.length - 1
      $scope.selectedFilters.listedDaysMax = "" + domSteps[$scope.domSlider.max]
    else
      delete $scope.selectedFilters.listedDaysMax

    $scope.selectedFilters.bedsMin = $scope.bedsMin
    $scope.selectedFilters.bathsMin = $scope.bathsMin

    $scope.close()
