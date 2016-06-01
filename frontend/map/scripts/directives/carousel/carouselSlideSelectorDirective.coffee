app = require '../../app.coffee'

# Slide selector add on for UI-Bootstrap Carousel
app.directive 'slideSelector', ($log) ->
  $log = $log.spawn 'Carousel Slide Selector'
  $log.debug "XXXXXXX Carousel Slide Selector directive"

  return {
    restrict: 'EA'
#    scope: {
#      slides: '='
#    }
    templateUrl: './includes/directives/carousel/_carouselSlideSelectorDirective.jade'
    controller: ($scope) ->
      $log.debug "!!!!!! Carousel Slide Selector", $scope.slides

      if $scope.slides?.length > 0
        $scope.slideSelectorCurrent = $scope.slides[0]

      $scope.$watchCollection 'slides', (newValue) ->
        $log.debug "????? Watch slides", newValue?.length, newValue
        if newValue?.length > 0
          $log.debug "????? Watch has LENGTH"
          $scope.slideSelectorCurrent = newValue[0]
  }
