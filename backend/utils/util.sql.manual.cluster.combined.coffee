config = require '../config/config'
zoomThresh = config.MAP.options.zoomThresh
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
logger = require '../config/logger'
dbs = require '../config/dbs'

_roundCoordCol = (roundTo = 0, scale = 1, xy = 'X') ->
  "round(ST_#{xy}(ST_CENTROID(geometry_raw))::decimal * #{scale},#{roundTo}) / #{scale}"

_makeClusterQuery = (roundTo, scale) ->
  query = tables.finalized.combined().select(
    dbs.get('main').raw('count(*)'),
    dbs.get('main').raw("count(case when status='not for sale' then 1 end) as notforsale"),
    dbs.get('main').raw("count(case when status='pending' then 1 end) as pending"),
    dbs.get('main').raw("count(case when status='sold' then 1 end) as sold"),
    dbs.get('main').raw("count(case when status='for sale' then 1 end) as forsale"),
    dbs.get('main').raw("#{_roundCoordCol(roundTo,scale)} as lng"),
    dbs.get('main').raw("#{_roundCoordCol(roundTo,scale,'Y')} as lat"))
  .whereNotNull('geometry_raw')
  .whereNotNull('address')
  .groupByRaw(_roundCoordCol(roundTo,scale))
  .groupByRaw(_roundCoordCol(roundTo,scale,'Y'))
  query

_getRoundingDigit = (zoom) ->
  return if zoom > zoomThresh.roundDigit then 1 else 0

_getRoundingScale = (zoom) ->
  scale = 1
  if zoom > zoomThresh.roundDigit
    scale = zoom - zoomThresh.roundDigit # zoom=9 -> 0, zoom=10 -> 1, zoom=11 -> 2
  else
    scale = zoom - zoomThresh.maxGrid
  if scale <= 0 then scale = 1
  scale

_clusterQuery = (zoom) ->
  digit = _getRoundingDigit(zoom)
  scale = _getRoundingScale(zoom)
  _makeClusterQuery(digit, scale)

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
