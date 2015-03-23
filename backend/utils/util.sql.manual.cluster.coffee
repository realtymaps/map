db = require('../config/dbs').properties
config = require '../config/config'
zoomThresh = config.MAP.options.zoomThresh
sqlHelpers = require './../utils/util.sql.helpers'
PropertyDetails = require "../models/model.propertyDetails"
logger = require '../config/logger'

_roundCoordCol = (roundTo = 0, xy = 'X') ->
  "round(ST_#{xy}(geom_point_raw)::decimal,#{roundTo})"

_makeClusterQuery = (roundTo) ->
  query = db.knex.select(db.knex.raw('count(*)'),
    db.knex.raw("#{_roundCoordCol(roundTo)} as lng"),
    db.knex.raw("#{_roundCoordCol(roundTo,'Y')} as lat"))
  .from(sqlHelpers.tableName(PropertyDetails))
  .whereNotNull('city')
  .groupByRaw(_roundCoordCol(roundTo))
  .groupByRaw(_roundCoordCol(roundTo,'Y'))

  # logger.sql query.toString()
  query

_clusterQuery = (zoom) ->
  if zoom <= zoomThresh.roundOne and zoom > zoomThresh.roundNone
    # logger.debug 'roundOne'
    _makeClusterQuery(1)
  else #none
    # logger.debug 'roundNone'
    _makeClusterQuery(0)

_fillOutDummyClusterIds = (properties) ->
  counter = 0
  # console.debug filteredProperties, true
  properties.map (obj) ->
    obj.id = counter
    obj.lat = Number obj.lat
    obj.lng = Number obj.lng
    counter += 1
    obj


module.exports =
  clusterQuery: _clusterQuery
  fillOutDummyClusterIds: _fillOutDummyClusterIds
