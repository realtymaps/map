_ = require 'lodash'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'
Promise = require 'bluebird'
sqlColumns = require('./util.sql.columns')
logger = require '../config/logger'

# MARGIN IS THE PERCENT THE BOUNDS ARE EXPANDED TO GRAB Extra Data around the view
_MARGIN = .25

_flattenLonLatImpl = (all, next) ->
  all.bindings.push(next.lon, next.lat)
  all.markers += ', ?, ?'
  return all

_flattenLonLat = (bounds) ->
  # flatten the last point as the initial value for reduce
  _.reduce bounds, _flattenLonLatImpl,
    bindings: [bounds[bounds.length-1].lon, bounds[bounds.length-1].lat]
    markers: '?, ?'

_whereRawSafe = (query, rawSafe) ->
  query.whereRaw rawSafe.sql, rawSafe.bindings

_orWhereRawSafe = (query, rawSafe) ->
  query.orWhere ()-> _whereRawSafe(@, rawSafe)

_orderByRawSafe = (query, rawSafe) ->
  query.orderByRaw rawSafe.sql, rawSafe.bindings

#TODO in sep PR remove this and all its dependencies
columns = sqlColumns.basicColumns

_getPartialPoint = (objOrArray, arrayDex, param) ->
  if _.isArray(objOrArray) then objOrArray[arrayDex] else objOrArray[param]

_getLat = (objOrArray) ->
  _getPartialPoint(objOrArray, 0, 'lat')

_getLon = (objOrArray) ->
  _getPartialPoint(objOrArray, 1, 'lon')

whereInBounds = (query, column, bounds) ->
  results = {}
  if bounds.length > 2
    # it must be a user-specified boundary
    boundsFlattened = _flattenLonLat(bounds)
    results.sql = "ST_WITHIN(#{column}, ST_GeomFromText(MULTIPOLYGON(((#{boundsFlattened.markers}))), #{coordSys.UTM}))"
    results.bindings = boundsFlattened.bindings
  else
    neLat = _getLat(bounds[0])
    neLon = _getLon(bounds[0])

    swLat = _getLat(bounds[1])
    swLon = _getLon(bounds[1])

    # it's the whole map, so let's put a margin on each side
    minLon = Math.min(neLon, swLon)
    maxLon = Math.max(neLon, swLon)
    marginLon = (maxLon - minLon)*_MARGIN
    minLat = Math.min(neLat, swLat)
    maxLat = Math.max(neLat, swLat)
    marginLat = (maxLat - minLat)*_MARGIN

    results.sql = "#{column} && ST_MakeEnvelope(?, ?, ?, ?, #{coordSys.UTM})"
    results.bindings = [ minLon-marginLon, minLat-marginLat, maxLon+marginLon, maxLat+marginLat ]
  _whereRawSafe query, results

whereIntersects = (query, geoPointJson, column = 'geom_polys_raw') ->
  results =
    sql: "ST_INTERSECTS(ST_GeomFromGeoJSON(?::text), #{column})"
    bindings: [geoPointJson]

  _whereRawSafe query, results
  query.raw = query.toString().replace(/\//g,'')#terrible hack for knex.. getting tired of doing this
  query

getClauseString = (query, remove = /.*where/) ->
  'WHERE '+ query.toString().replace(remove,'')

whereIn = (query, column, values) ->
  # this logic is necessary to avoid SQL parse errors
  if values.length == 0
    query.whereRaw('FALSE')
  else if values.length == 1
    query.where(column, values[0])
  else
    query.whereIn(column, values)

orWhereIn = (query, column, values) ->
  query.orWhere () -> whereIn(@, column, values)

whereNotIn = (query, column, values) ->
  # this logic is necessary to avoid SQL parse errors
  if values.length == 0
    query.whereRaw('TRUE')
  else if values.length == 1
    query.where(column, '!=', values[0])
  else
    query.whereNotIn(column, values)

orWhereNotIn = (query, column, values) ->
  query.orWhere () -> whereNotIn(@, column, values)

between = (query, column, min, max) ->
  if min and max
    query.whereBetween(column, [min, max])
  else if min
    query.where(column, '>=', min)
  else if max
    query.where(column, '<=', max)

ageOrDaysFromStartToNow = (query, listingAge, beginDate, operator, val) ->
  _whereRawSafe query,
    sql: "#{sqlColumns.ageOrDaysFromStartToNow(listingAge, beginDate)} #{operator} ?"
    bindings: [ val ]

orderByDistanceFromPoint = (query, column, point) ->
  # order by distance from point
  # http://boundlessgeo.com/2011/09/indexed-nearest-neighbour-search-in-postgis/
  #geom <-> st_setsrid(st_makepoint(-90,40),4326)
  _orderByRawSafe query,
    sql: "#{column} <-> st_setsrid(st_makepoint(?,?),#{coordSys.UTM})"
    bindings: [point.longitude, point.latitude]

allPatternsInAnyColumn = (query, patterns, columns) ->
  patterns.forEach (pattern) ->
    query.where () ->
      subquery = @
      columns.forEach (column) ->
        _orWhereRawSafe subquery,
          sql: "#{column} ~* ?"
          bindings: [ pattern ]

select = (knex, which, passedFilters=null, prepend='') ->
  prepend += ' ' if prepend?
  extra = ''
  if passedFilters
    extra = ", #{passedFilters} as \"passedFilters\""
  knex.select(knex.raw(prepend + columns[which] + extra))
  knex

selectCountDistinct = (knex, distinctField='rm_property_id') ->
  # some other (possibly preferred) query structure not available,
  # using tip described via https://github.com/tgriesser/knex/issues/238
  knex.select(knex.raw("count(distinct #{distinctField})"))
  knex

singleRow = (rows) -> Promise.try ->
  if !rows?.length
    return null
  return rows[0]

expectSingleRow = (rows) -> Promise.try ->
  if !rows?.length
    throw new Error('Expected a single result and rows are empty!')
  if !rows[0]?
    throw new Error("Expected a single result and row is #{rows[0]}")  # undefined or null
  return rows[0]

isUnique = (tableFn, whereClause, id, name = 'Entity') ->
  query = tableFn().where(whereClause).count()

  query = query.whereNot(id:id) if id?

  logger.debug query.toString()

  query.then singleRow
  .then (row) ->
    if row.count > 0
      return Promise.reject new Error("#{name} already exists")
    true

safeJsonArray = (arr) ->
  # this function is minor a hack to deal with the fact that knex can't easily distinguish between a PG-array and a
  # JSON array when serializing to SQL, plus to ensure we get a db-NULL instead of a JSON null
  if !arr?
    return arr
  JSON.stringify(arr)

sqlizeColName = (fullName) ->
  fullName.split('.').map (name) ->
    '"' + name + '"'
  .join('.')

module.exports =
  between: between
  ageOrDaysFromStartToNow: ageOrDaysFromStartToNow
  orderByDistanceFromPoint: orderByDistanceFromPoint
  allPatternsInAnyColumn: allPatternsInAnyColumn
  select: select
  selectCountDistinct: selectCountDistinct
  singleRow: singleRow
  expectSingleRow: expectSingleRow
  whereIn: whereIn
  orWhereIn: orWhereIn
  whereNotIn: whereNotIn
  orWhereNotIn: orWhereNotIn
  whereInBounds: whereInBounds
  getClauseString: getClauseString
  safeJsonArray: safeJsonArray
  isUnique: isUnique
  columns: columns
  whereIntersects: whereIntersects
  sqlizeColName: sqlizeColName
