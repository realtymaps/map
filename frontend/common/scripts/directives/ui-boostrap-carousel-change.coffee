mod = require '../module.coffee'

mod.directive 'onCarouselChange', ($parse) ->
  return {
    require: 'carousel'
    link: (scope, element, attrs, carouselCtrl) ->
      fn = $parse(attrs.onCarouselChange)
      origSelect = carouselCtrl.select
      carouselCtrl.select = (nextSlide, direction) ->
        fn scope, {
          nextSlide: nextSlide,
          direction: direction,
        }

        return origSelect.apply(this, arguments)
  }
