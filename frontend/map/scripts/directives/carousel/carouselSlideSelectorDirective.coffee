app = require '../../app.coffee'

# Show slide selector in carousel
app.directive 'showSlideSelector', () ->
  return {
    restrict: 'A'
    require: '^carousel'
    link: ($scope, $elem, $attrs, carouselCtrl) ->
      origSelect = carouselCtrl.select
      carouselCtrl.select = (nextSlide, direction) ->
        if $scope.selectorScope
          $scope.selectorScope.slideSelectorCurrent = nextSlide

        return origSelect.apply(this, arguments)

    controller: ($scope) ->
      registerSlideSelector: (selectorScope) ->
        $scope.selectorScope = selectorScope
  }

# Slide selector add on for UI-Bootstrap Carousel
app.directive 'slideSelector', () ->
  return {
    restrict: 'EA'
    require: '^?showSlideSelector'
    templateUrl: './includes/directives/carousel/_carouselSlideSelectorDirective.jade'
    controller: ($scope) ->
      if $scope.slides?.length > 0
        $scope.slideSelectorCurrent = $scope.slides[0]

      $scope.$watchCollection 'slides', (newValue) ->
        if newValue?.length > 0
          $scope.slideSelectorCurrent = newValue[0]

    link: ($scope, $elem, $attrs, showSlideSelectorCtrl) ->
      if showSlideSelectorCtrl
        showSlideSelectorCtrl.registerSlideSelector($scope)
      else
        $scope.hideSlideSelector = true

  }
