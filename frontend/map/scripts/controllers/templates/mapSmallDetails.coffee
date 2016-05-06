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
      host = $scope.property.cdn_photo.split('/')[0]
      photos.push
        key: i
        # A bug in the photo service was sometimes crashing the app so for now this will skip the cdn.
        # url: $scope.property.cdn_photo + "&width=#{PHOTO_WIDTH}&image_id=#{i}"
        url: $scope.property.cdn_photo.replace(host, '') + "&width=#{PHOTO_WIDTH}&image_id=#{i}"

  $scope.property.photos = photos
  $log.debug $scope.property.photos
