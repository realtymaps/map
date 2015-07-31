db = require('../config/dbs').properties
config = require '../config/config'
zoomThresh = config.MAP.options.zoomThresh
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
logger = require '../config/logger'

_roundCoordCol = (roundTo = 0, xy = 'X') ->
  "round(ST_#{xy}(geom_point_raw)::decimal,#{roundTo})"

_makeClusterQuery = (roundTo) ->
  query = tables.propertyData.propertyDetails().select(db.knex.raw('count(*)'),
    db.knex.raw("#{_roundCoordCol(roundTo)} as lng"),
    db.knex.raw("#{_roundCoordCol(roundTo,'Y')} as lat"))
  .whereNotNull('city')
  .groupByRaw(_roundCoordCol(roundTo))
  .groupByRaw(_roundCoordCol(roundTo,'Y'))
  query

_clusterQuery = (zoom) ->
  if zoom <= zoomThresh.roundOne and zoom > zoomThresh.roundNone
    _makeClusterQuery(1)
  else #none
    _makeClusterQuery(0)

_fillOutDummyClusterIds = (properties) ->
  counter = 0
  properties.map (obj) ->
    obj.id = counter
    obj.lat = Number obj.lat
    obj.lng = Number obj.lng
    counter += 1
    obj


module.exports =
  clusterQuery: _clusterQuery
  fillOutDummyClusterIds: _fillOutDummyClusterIds
