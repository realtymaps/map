_ = require 'lodash'

boundsService = {
  boundsFromPropertyArray: (properties) ->
    maxLat = -90
    minLat = 90
    maxLng = -180
    minLng = 180

    if !properties or properties.length == 0
      return

    _.forEach properties, (property) ->
      if property.geometry_center?.coordinates?
        if property.geometry_center.coordinates[1] > maxLat
          maxLat = property.geometry_center.coordinates[1]

        if property.geometry_center.coordinates[1] < minLat
          minLat = property.geometry_center.coordinates[1]

        if property.geometry_center.coordinates[0] > maxLng
          maxLng = property.geometry_center.coordinates[0]

        if property.geometry_center.coordinates[0] < minLng
          minLng = property.geometry_center.coordinates[0]


    return {
      northEast: {
        lat: maxLat,
        lng: maxLng
      },
      southWest: {
        lat: minLat,
        lng: minLng
      }
    }
}


#
# Export for Require statements
#
module.exports = boundsService

#
# Expose as an Angular Service on the Common Utils module
#
if window?.angular?
  commonUtilsModule = require './angularModule.coffee'
  commonUtilsModule.factory 'rmapsBounds', () ->
    return module.exports
