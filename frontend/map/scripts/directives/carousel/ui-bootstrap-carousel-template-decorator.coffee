app = require '../../app.coffee'

app.config ($provide) ->
  $provide.decorator 'carouselDirective', ($delegate, $log) ->
    # Replace the UI Bootstrap CAROUSEL default Template
    $delegate[0].templateUrl = (element, attrs) ->
      return attrs.templateUrl || './includes/bootstrap/carousel.jade'

    return $delegate

app.config ($provide) ->
  $provide.decorator 'slideDirective', ($delegate, $log) ->
    # Replace the UI Bootstrap SLIDE default Template
    $delegate[0].templateUrl = (element, attrs) ->
      return attrs.templateUrl || './includes/bootstrap/carousel-slide.jade'

    return $delegate

