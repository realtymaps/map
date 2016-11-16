_ = require 'lodash'

class Point
  constructor: (maybeObjOrLat, maybeLon) ->
    @longitude = @latitude = @lon = @lat = @lng = null
    @setLat = (lat) =>
      @latitude = @lat = Number(lat)
    @setLon = (lon) =>
      @lng = @longitude = @lon = Number(lon)

    if _.isNumber(maybeObjOrLat) and _.isNumber(maybeLon)
      @setLat maybeObjOrLat
      @setLon maybeLon
      return @

    _isLatLonObject = Boolean(
      (maybeObjOrLat?.lat? and maybeObjOrLat?.lon?) or
        (maybeObjOrLat?.lat? and maybeObjOrLat?.lng?) or
        (maybeObjOrLat?.latitude? and maybeObjOrLat?.longitude?)
    )

    if _.isObject(maybeObjOrLat) and _isLatLonObject
      @setLat maybeObjOrLat?.lat or maybeObjOrLat?.latitude
      @setLon maybeObjOrLat?.lon or maybeObjOrLat?.lng or maybeObjOrLat?.longitude
      return @
    throw new Error('Arguments incorrect for Point')

  isEqual: (other) ->
    other.lat == @lat && other.lon == @lon

  toJSON: () ->
    {
      @lat
      @lon
      @latitiude
      @longitude
    }

class LeafletPoint extends Point
  constructor: (lat, lon) ->
    super(lat, lon)

class BackendPoint extends Point
  constructor: (lon, lat) ->
    super(lat, lon)

class LeafletCenter extends LeafletPoint
  constructor: (lat, lon, zoom) ->
    super(lat, lon)
    @zoom = Number zoom

  isEqual: (other) ->
    super(other) && other.zoom == @zoom

  setZoom: (zoom) ->
    @zoom = Number zoom

  toJSON: () ->
    json = super()
    json.zoom = @zoom
    json

class GeoJsonCenter extends LeafletCenter
  constructor: (geojson, zoom) ->
    super(geojson.coordinates[1],geojson.coordinates[0], zoom)

NgLeafletCenter = (pointWZoom) ->
  new LeafletCenter(pointWZoom, null, pointWZoom.zoom)

#
# Export for Require statements
#
module.exports = {
  LeafletPoint
  BackendPoint
  Point
  LeafletCenter
  GeoJsonCenter
  NgLeafletCenter
}

#
# Expose as an Angular Service on the Common Utils module
#
if window?.angular?
  commonUtilsModule = require './angularModule.coffee'
  commonUtilsModule.factory 'rmapsGeometries', () ->
    return module.exports
