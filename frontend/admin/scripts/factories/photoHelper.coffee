app = require '../app.coffee'
photoHelperTemplate = require('../../html/views/templates/photoHelper.jade')()
_ = require 'lodash'
require 'font-awesome/css/font-awesome.css'


module.exports = app.factory 'rmapsPhotoHelper', (
$log
$timeout
$uibModal
rmapsMlsService) ->
  $log = $log.spawn("rmapsPhotoHelper")

  ($scope) -> () ->
    $scope.photoHelper =
      photos: []
      isReady: false

    modal = $uibModal.open
      animation: $scope.animationsEnabled
      template: photoHelperTemplate
      controller: 'rmapsModalInstanceCtrl'
      size: '90'
      resolve: model: -> $scope

    $scope.photoHelper.close = modal.close

    rmapsMlsService.getPhotoIds({
      mlsId: $scope.mlsData.current.id
      uuidField: $scope.mlsData.current.listing_data.mlsListingId.name
      photoIdField: $scope.mlsData.current.listing_data.photoId.name
      lastModTimeField: $scope.mlsData.current.listing_data.lastModTime.name
      limit: 5
    })
    .then (ids) ->
      photoTypes = $scope.mlsData.current.listing_data.photoObjects || $scope.fieldNameMap.objects

      $scope.photos = _.flatten photoTypes.map (photoType) ->
        ids.map ({photo_id}) ->
          photoId = photo_id

          urlOpts = {
            mlsId: $scope.mlsData.current.id,
            photoId
            imageId: 0
            photoType: photoType || 'Photo'
          }
          if $scope.mlsData.current.listing_data.Location? && $scope.mlsData.current.listing_data.Location != 0
            urlOpts.objectsOpts = {Location:$scope.mlsData.current.listing_data.Location}
          url = rmapsMlsService.buildPhotoUrl(urlOpts)

          return {
            url
            info: photoType
            click: () ->
              $scope.mlsData.current.listing_data.largestPhotoObject = @info
              modal.close()
          }
    .then (photos) ->
      $scope.photoHelper.photos = photos

      modal.rendered
      .then () ->
        $timeout -> #must be a bug in angular-ui-bootstrap as flickity is not always there
          $scope.photoHelper.isReady = true
        , 200
