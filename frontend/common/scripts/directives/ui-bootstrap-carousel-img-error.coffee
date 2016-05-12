mod = require '../module.coffee'

mod.directive 'carouselImageError', ($parse, $log) ->
  $log = $log.spawn 'carouselImageError'
  $log.debug 'init'

  require: 'carousel'
  link: (scope, element, attrs, carouselCtrl) ->
    $log.debug "linking #{element} #{attrs.carouselImageError}"

    placeholderImage = attrs.carouselImageError || 'http://fpoimg.com/300x250'

    handler = (element) ->
      $log.debug "handler called on #{element}"
      img = element.find('img')?[0]
      img?.onerror = ->
        img.onerror = null
        img.src = placeholderImage

    carouselAddSlide = carouselCtrl.addSlide
    carouselCtrl.addSlide = (slide, element) ->
      $log.debug "addSlide called on #{slide} #{element}"
      handler element
      carouselAddSlide.apply this, arguments
