module = require '../module.coffee'
Flickity = require 'flickity-imagesloaded'
_ = require 'lodash'
require 'flickity/dist/flickity.min.css'


module.directive 'rmapsFlickity', (
$log
$timeout
) ->

  $log = $log.spawn 'rmapsFlickityDirective'

  defaultOptions =
    contain: true
    cellAlign: 'center'
    imagesLoaded: true
    lazyLoad: 1


  restrict: 'EA'
  templateUrl: './includes/directives/flickity.jade'

  scope:
    options: '@'
    photos: '='
    ready: '=?'

  link: ($scope, $element) ->
    flickity = null

    getOptions = () ->
      if typeof $scope.options == 'string'
        options = JSON.parse($scope.options)

      _.extend({}, defaultOptions, options || {})

    create = () ->
      if flickity?
        flickity.destroy()
        flickity = null

      element = $element[0].querySelector('.flickity')

      if !element
        $log.error "Element undefined; not creating. Consider using ready binding."
        return

      flickity = new Flickity(element, getOptions())

    $scope.$watch 'ready', (newVal, oldVal) ->
      if(newVal)
        return create()

      if !oldVal && flickity?
        flickity.destroy()


    #NOTE: if this needs to be thorough then add watch to clean and re-create Flickity
    if !$scope.ready?
      create()

    $scope.$on '$destroy', ->
      return if !flickity
      flickity.destroy()
      flickity = null
