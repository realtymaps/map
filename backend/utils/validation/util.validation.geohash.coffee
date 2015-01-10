Promise = require "bluebird"
geohash64 = require 'geohash64'
ParamValidationError = require './util.error.paramValidation'
coordSys = require '../../../common/utils/enums/util.enums.map.coord_system'


flattenLonLatImpl = (all, next) ->
  all.bindings.push(next.lon, next.lat)
  all.markers += ", ?, ?"
  return all

flattenLonLat = (bounds) ->
  # flatten the last point as the initial value for reduce
  init =
    bindings: [bounds[bounds.length-1].lon, bounds[bounds.length-1].lat]
    markers: '?, ?'
  _.reduce bounds, flattenLonLatImpl, init

# MARGIN IS THE PERCENT THE BOUNDS ARE EXPANDED TO GRAB Extra Data around the view
#%50 is way too huge!
_MARGIN = .10

module.exports =

  decode: (param, boundsStr) ->
    Promise.try () ->
      geohash64.decode(boundsStr)
    .catch (err) ->
      Promise.reject new ParamValidationError("error decoding geohash string", param, boundsStr)

  transformToRawSQL: (options = {}) ->
    (param, bounds) ->
      Promise.try () ->
        results = {}
        if bounds.length > 2
          boundsFlattened = flattenLonLat(bounds)
          results.sql = "ST_WITHIN(#{options.column}, ST_GeomFromText(MULTIPOLYGON(((#{boundsFlattened.markers}))), #{options.coordSys}))"
          results.bindings = boundsFlattened.bindings
        else
          # whole map, so let's put a margin on each side
          minLon = Math.min(bounds[0].lon, bounds[1].lon)
          maxLon = Math.max(bounds[0].lon, bounds[1].lon)
          marginLon = (maxLon - minLon)*_MARGIN
          minLat = Math.min(bounds[0].lat, bounds[1].lat)
          maxLat = Math.max(bounds[0].lat, bounds[1].lat)
          marginLat = (maxLat - minLat)*_MARGIN

          results.sql = "#{options.column} && ST_MakeEnvelope(?, ?, ?, ?, #{options.coordSys})"
          results.bindings = [ minLon-marginLon, minLat-marginLat, maxLon+marginLon, maxLat+marginLat ]
        return results
      .catch (err) ->
        return Promise.reject new ParamValidationError("problem processing decoded data", param, bounds)
