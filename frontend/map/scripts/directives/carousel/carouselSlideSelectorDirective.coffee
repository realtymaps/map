app = require '../../app.coffee'


###

  USAGE:

  carousel.carousel-standard(
    slide-selector
    slide-selector-label="actual.address.street"
  )
    slide(ng-repeat="property in pins" actual="property")
      div SLIDE CONTENT GOES HERE

  EXPLANATION

    slide-selector - required attribute Directive that enables the slide selector tool feature
    slide-selector-label - optional attribute Directive that takes an AngularJS expression.  This is used
                           to create the values that display in the Select input control

    slide.actual - This property of the Carousel Slide directive is required because it sets the model
                   object that will be passed to the slide-selector-label expression as the "actual" value

###

# Show slide selector in carousel
###eslint-disable###
app.directive 'slideSelector', ($log) ->
  ###eslint-enable###
  return {
    restrict: 'A'
    require: '^uibCarousel'
    priority: 0
    link: ($scope, $elem, $attrs, carouselCtrl) ->
      origSelect = carouselCtrl.select
      ###eslint-disable###
      carouselCtrl.select = (nextSlide, direction) ->
        ###eslint-enable###
        if $scope.selectorScope
          $scope.selectorScope.slideSelectorCurrent = nextSlide

        return origSelect.apply(this, arguments)

    controller: ($scope) ->
      registerSlideSelector: (selectorScope) ->
        $scope.selectorScope = selectorScope
        $scope.selectorScope.selectorLabelFn = $scope.selectorLabelFn
        $scope.selectorScope.carouselParentScope = $scope.$parent

      setLabelFunction: (labelFn) ->
        $scope.selectorLabelFn = labelFn
        if $scope.selectorScope?
          $scope.selectorScope.selectorLabelFn = labelFn
  }

###eslint-disable###
app.directive 'slideSelectorLabel', ($parse, $log) ->
  ###eslint-enable###
  return {
    restrict: 'A'
    require: 'slideSelector'
    link: ($scope, $elem, $attrs, showSlideSelectorCtrl) ->
      # Parse the label function and pass it to the coordinating showSlideSelector directive
      # so that it can be passed to the actual selector directive
      fn = $parse($attrs.slideSelectorLabel)
      showSlideSelectorCtrl.setLabelFunction(fn)
  }

# Slide selector add on for UI-Bootstrap Carousel
###eslint-disable###
app.directive 'slideSelectorControl', ($log) ->
  ###eslint-enable###
  return {
    restrict: 'EA'
    require: '^?slideSelector'
    templateUrl: './includes/directives/carousel/_carouselSlideSelectorDirective.jade'
    controller: ($scope) ->
      if $scope.slides?.length > 0
        $scope.slideSelectorCurrent = $scope.slides[0]

      $scope.$watchCollection 'slides', (newValue) ->
        if newValue?.length > 0
          $scope.slideSelectorCurrent = newValue[0]

      $scope.getLabel = (slide) ->
        if $scope.selectorLabelFn
          return $scope.selectorLabelFn($scope.carouselParentScope || $scope, {
            actual: slide.actual
          })

        idx = ($scope.indexOfSlide(slide) + 1)
        return 'Slide ' + idx
    ###eslint-disable###
    link: ($scope, $elem, $attrs, slideSelectorCtrl, carouselCtrl) ->
      ###eslint-enable###
      if slideSelectorCtrl
        slideSelectorCtrl.registerSlideSelector($scope)
      else
        $scope.hideSlideSelector = true

  }
