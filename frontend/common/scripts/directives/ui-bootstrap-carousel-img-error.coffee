mod = require '../module.coffee'

mod.directive 'carouselImageError', ($parse, $log) ->
  $log = $log.spawn 'carouselImageError'
  $log.debug 'init'

  require: 'carousel'
  link: (scope, element, attrs, carouselCtrl) ->
    $log.debug "linking #{element} #{attrs.carouselImageError}"

    placeholderImage = attrs.carouselImageError

    addEvents = (element) ->
      $log.debug "addEvents called on #{element}"
      img = element.find('img')?[0]
      img?.onerror = ->
        img.onerror = null
        img.src = placeholderImage
      img?.onload = ->
        $log.debug "image loaded #{img.src}"
        scope.$emit 'imageLoaded', img

    carouselAddSlide = carouselCtrl.addSlide
    carouselCtrl.addSlide = (slide, element) ->
      $log.debug "addSlide called on #{slide} #{element}"
      addEvents element
      carouselAddSlide.apply this, arguments
