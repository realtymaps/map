app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsSmallDetailsCtrl', ($scope, $log, rmapsResultsFormatterService, rmapsPropertyFormatterService) ->
  $log = $log.spawn 'rmapsSmallDetailsCtrl'
  $log.debug "rm_property_id: #{JSON.stringify $scope.model.rm_property_id}"

  PHOTO_WIDTH = 275

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  $scope.property = _.cloneDeep $scope.model

  photos = []
  if $scope.property.cdn_photo && $scope.property.photo_count
    for i in [1..$scope.property.photo_count]
      photos.push
        key: i
        url: $scope.property.cdn_photo + "&width=#{PHOTO_WIDTH}&image_id=#{i}"
        # Uncomment this to load photos locally
        # url: $scope.property.cdn_photo.replace($scope.property.cdn_photo.split('/')[0], '') + "&width=#{PHOTO_WIDTH}&image_id=#{i}"

  $scope.property.photos = photos
  $log.debug $scope.property.photos
