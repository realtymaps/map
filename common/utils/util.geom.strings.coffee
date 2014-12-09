###
  Goal of this lib is to produce useful PostGIS strings which are frequently used
###
coordSys = require './enums/util.enums.map.coord_system.coffee'
keysToValue = require './util.keys_to_values.coffee'

#TODO: This lib is a candidate to be outsources as a OSS npm / bower package
#/////////////////////////////// OBJECTS
#postgis gis objects
geomEnums =
  MULTIPOLYGON: undefined
  POLYGON: undefined
  POINT: undefined

geomEnums = keysToValue(geomEnums)
ge = geomEnums

#postgis stored procedures / functions
postgisProcs =
  ST_AsGeoJSON: undefined
  ST_MakeEnvelope: undefined

postgisProcs = keysToValue(postgisProcs)
pgp = postgisProcs

#/////////////////////////////// FUNCTIONS
pathsToBounds = (paths)->
  isFirst = true
  # lat's lon's, geojson to POSTGIS strings or something
  boundsStr = _.reduce paths, (all, next) ->
    unless isFirst
      "#{all} #{next.lon} #{next.lat}, "
    else
      isFirst = false
      "#{all.lon} #{all.lat}, #{next.lon} #{next.lat}, "
  boundsStr += "#{paths[0].lon} #{paths[0].lat}"

multiPolygon = (paths) ->
  boundsStr = pathsToBounds paths
  "'#{ge.MULTIPOLYGON}(((#{boundsStr})))'"

makeEnvelope = (box, coord = coordSys.WGS84) ->
  pgp.ST_MakeEnvelope + "(#{box[1].lon}, #{box[1].lat}, #{box[0].lon}, #{box[0].lat}, #{coord})"


module.exports =
  #objects
  geomEnums: geomEnums
  postgisProcs: postgisProcs
  #functions
  pathsToBounds: pathsToBounds
  multiPolygon: multiPolygon
  makeEnvelope: makeEnvelope
