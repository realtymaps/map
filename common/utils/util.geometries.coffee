_ = require 'lodash'

_point = (maybeObjOrLat, maybeLon) ->
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


_ngLeafletCenter = (pointWZoom) ->
  zoom = Number pointWZoom.zoom
  numericPoint = new _point pointWZoom
  numericPoint.zoom = zoom
  numericPoint.setZoom = (zoom) ->
    numericPoint.zoom = Number zoom
  numericPoint

module.exports =
  Point: _point
  NgLeafletCenter: _ngLeafletCenter
