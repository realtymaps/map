app = require '../../app.coffee'

app.directive 'carouselImageError', ($parse, $log) ->
  $log = $log.spawn 'carouselImageError'

  require: 'uibCarousel'
  link: (scope, element, attrs, carouselCtrl) ->

    placeholderImage = attrs.carouselImageError

    addEvents = (element) ->
      img = element.find('img')?[0]
      origOnError = img.onerror
      img?.onerror = ->
        if origOnError?
          origOnError()
          origOnError = null
        img.onerror = null
        img.src = placeholderImage
      origOnLoad = img.onload
      img?.onload = ->
        origOnLoad?()
        $log.debug "image loaded #{img.src}"
        scope.$emit 'imageLoaded', img

    carouselAddSlide = carouselCtrl.addSlide
    carouselCtrl.addSlide = (slide, element) ->
      addEvents element
      carouselAddSlide.apply this, arguments
