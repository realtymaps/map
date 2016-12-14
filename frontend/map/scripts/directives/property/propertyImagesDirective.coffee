app = require '../../app.coffee'
Flickity = require 'flickity-imagesloaded'

app.directive 'propertyImages', (
  $log
  $timeout
  rmapsPropertyFormatterService
  rmapsResultsFormatterService
) ->

  $log = $log.spawn 'propertyImagesDirective'

  restrict: 'EA'
  templateUrl: './includes/directives/property/_propertyImagesDirective.jade'
  scope:
    propertyParent: '=property'
    imageWidth: '@'
    imageHeight: '@'
    coverImage: '@'
    panoramaControls: '@'
    showStatusVal: '@showStatus'

  controller: ($scope, $element) ->

    $scope.flickityOptions =
      contain: true
      cellAlign: 'center'
      imagesLoaded: true
      lazyLoad: 1
      pageDots: false

    $scope.active = 0
    $scope.showStatus = ($scope.showStatusVal?.toLowerCase() == 'true')

    $scope.formatters = {
      results: new rmapsResultsFormatterService  scope: $scope
      property: rmapsPropertyFormatterService
    }

    $scope.panorama =
      status: 'loading' # cannot be null or angular google maps doesn't set it?

    $scope.panoramaOk = ->
      if !$scope.panorama.status? || $scope.panorama.status == 'loading'
        return true
      else
        return $scope.panorama.status == 'OK'

    if $scope.propertyParent
      $scope.property = angular.copy($scope.propertyParent)
    else
      $log.error("Property Images Directive was not passed a Property")

    imageLoaded = (event, img) ->
      $timeout ->
        $scope.$evalAsync()
      , 50

    photos = []
    if $scope.property.cdn_photo && $scope.property.actual_photo_count
      resizeUrl = $scope.property.cdn_photo
      if resizeUrl.slice(0,4) != "http"
        resizeUrl = "//#{resizeUrl}"

      # uncomment to load photos locally
      # resizeUrl = $scope.property.cdn_photo.replace($scope.property.cdn_photo.split('/')[0], '')

      if $scope.imageWidth
        resizeUrl += "&width=#{$scope.imageWidth}"
      if $scope.imageHeight
        resizeUrl += "&height=#{$scope.imageHeight}"

      numPhotos = $scope.property.actual_photo_count - 1
      if $scope.coverImage
        numPhotos = 1
      else if numPhotos == 1
        $scope.coverImage = true

      # Skip the first image, it is expected to be a duplicate
      for i in [1..numPhotos]
        photos.push
          index: i - 1
          url: "#{resizeUrl}&image_id=#{i}"

      if !$scope.coverImage
        $timeout ->
          $log.debug new Flickity($element.find('flickity')[0], $scope.flickityOptions)
        , 50

    imageLoaded()

    $scope.property.photos = photos
    # $log.debug $scope.property.photos

    $scope.$on 'imageLoaded', imageLoaded
