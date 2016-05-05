app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersMobileCtrl', ($scope, $filter, $timeout, rmapsFiltersFactory, $log) ->
  $log = $log.spawn 'rmapsFiltersMobileCtrl'

  MAX_PRICE = 10000000
  MAX_SIZE = 10000
  MIN_BEDS = 0
  MAX_BEDS = 10
  MIN_BATHS = 0
  MAX_BATHS = 6
  MAX_DOM = 365

  #
  # Initialize values for filter options in the select tags
  #
  $scope.filterValues = rmapsFiltersFactory.values

  #
  # Dirty tracking
  #
  $scope.makeDirty = ->
    $timeout ->
      $log.debug 'marking dirty'
      $scope.dirty = true

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
  # Set Slider default values from pre-selected filters
  #
  setSliderMinMax = (config, presetMin, presetMax) ->
    steps = config.options.stepsArray

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

    config.min = stepMinIdx
    config.max = stepMaxIdx

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

    config =
      min: minValue
      max: maxValue
      options:
        floor: minValue,
        ceil: maxValue
        stepsArray: steps
        hideLimitLabels: true
        onChange: $scope.makeDirty

  $scope.priceSlider = initSliderConfig 0, MAX_PRICE, priceSteps, $scope.selectedFilters.priceMin, $scope.selectedFilters.priceMax
  $scope.sizeSlider = initSliderConfig 0, MAX_SIZE, sizeSteps, $scope.selectedFilters.sqftMin, $scope.selectedFilters.sqftMax
  $scope.bedsSlider = options: floor: MIN_BEDS, ceil: MAX_BEDS, step: 1, onChange: $scope.makeDirty
  $scope.bathsSlider = options: floor: MIN_BATHS, ceil: MAX_BATHS, step: 0.5, precision: 1, onChange: $scope.makeDirty
  $scope.domSlider = initSliderConfig 0, MAX_DOM, domSteps, $scope.selectedFilters.listedDaysMin, $scope.selectedFilters.listedDaysMax

  $timeout (() ->
    $scope.$broadcast 'reCalcViewDimensions'
    $timeout (() ->
      $scope.$broadcast 'rzSliderForceRender'
      , 10)
    , 10)

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
  $scope.reset = () ->
    $scope.bedsMin = $scope.selectedFilters.bedsMin || MIN_BEDS
    $scope.bathsMin = $scope.selectedFilters.bathsMin || MIN_BATHS

    setSliderMinMax $scope.priceSlider, $scope.selectedFilters.priceMin, $scope.selectedFilters.priceMax
    setSliderMinMax $scope.sizeSlider, $scope.selectedFilters.sqftMin, $scope.selectedFilters.sqftMax
    setSliderMinMax $scope.domSlider, $scope.selectedFilters.listedDaysMin, $scope.selectedFilters.listedDaysMax

    $scope.dirty = false


  #
  # Initialize scope values from the global filters
  #
  $scope.reset()

  #
  # Apply the filter changes to the map results
  #
  $scope.apply = () ->
    return if !$scope.dirty

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
