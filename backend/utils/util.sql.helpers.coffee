_ = require 'lodash'
memoize = require 'memoizee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'
logger = require '../config/logger'
Promise = require 'bluebird'
util = require 'util'

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

_ageOrDaysFromStartToNow = (listingAge, beginDate) ->
  "COALESCE(#{listingAge}, now()::DATE - #{beginDate})"

_parcel = [
  'rm_property_id', 'street_address_num', 'geom_polys_json AS geometry',
  '\'Feature\' AS type',
  'fips_code', '\'{}\'::json AS properties'
]

_commonProjectCols = ['id', 'auth_user_id', 'project_id']

columns =
  # columns returned for filter requests
  filter: [
    'rm_property_id', 'street_address_num', 'street_address_name', 'street_address_unit', 'geom_polys_json AS geometry',
    'geom_point_json', 'rm_status', 'owner_name', 'owner_name2', 'year_built', 'acres', 'finished_sqft', 'baths_full',
    'baths_half', 'baths_total', 'bedrooms', 'price', 'assessed_value', 'city', 'state', 'zip',
    'owner_street_address_num', 'owner_street_address_name', 'owner_street_address_unit', 'owner_city', 'owner_state',
    'owner_zip'
  ].join(', ')
  # columns returned for additional detail results
  detail: [
    'annual_tax', 'tax_desc', 'property_indication_category', 'property_indication_name', 'zoning',
    'year_modified', 'ask_price', 'prior_sale_price', 'original_price', 'close_price', 'mortgage_amount',
    'listing_start_date', 'close_date', 'mortgage_date', 'recording_date', 'title_company_name',
    'building_desc', 'building_design', 'development_name', 'equipment', 'garage_spaces', 'garage_desc', 'heat',
    'hoa_fee', 'hoa_fee_freq', 'list_agent_mui_id', 'list_agent_mls_id', 'list_agent_phone', 'list_agent_name',
    'selling_agent_mui_id', 'selling_agent_mls_id', 'selling_agent_phone', 'selling_agent_name', 'matrix_unique_id',
    'mls_name', 'sewer', 'assessed_year', 'property_information', 'land_square_footage', 'lot_front_footage',
    'depth_footage', 'mls_close_date', 'mls_close_price', 'sale_date', 'sale_price', 'prior_sale_date',
    "#{_ageOrDaysFromStartToNow('listing_age_days', 'listing_start_date')} AS listing_age",
  ].join(', ')
  # columns returned for full detail results, with geom_polys_json AS geometry for geojson standard
  all_detail_geojson: [
    'rm_property_id', 'has_mls', 'has_tax', 'has_deed', 'street_address_num', 'street_address_name', 'street_address_unit',
    'city', 'state', 'zip', 'geom_polys_raw', 'geom_point_raw', 'geom_polys_json AS geometry', 'geom_point_json', 'close_date',
    'owner_name', 'owner_name2_raw', 'owner_street_address_num', 'owner_street_address_name', 'owner_street_address_unit',
    'owner_city', 'owner_state', 'owner_zip', 'annual_tax', 'tax_desc', 'property_indication_category', 'property_indication_name',
    'zoning', 'year_built', 'year_modified', 'acres', 'finished_sqft', 'baths_full', 'baths_half', 'baths_total', 'bedrooms',
    'ask_price', 'prior_sale_price', 'prior_sale_date', 'original_price', 'close_price', 'mls_close_date', 'mls_close_price',
    'sale_date', 'sale_price', 'mortgage_amount', 'listing_start_date', 'listing_age_days', 'mortgage_date', 'recording_date',
    'title_company_name', 'building_desc', 'building_design', 'development_name', 'equipment', 'garage_spaces', 'garage_desc',
    'heat', 'hoa_fee', 'hoa_fee_freq', 'list_agent_mui_id', 'list_agent_mls_id', 'list_agent_phone', 'list_agent_name',
    'selling_agent_mui_id', 'selling_agent_mls_id', 'selling_agent_phone', 'selling_agent_name', 'matrix_unique_id', 'mls_name',
    'sewer', 'assessed_value', 'assessed_year', 'property_information', 'land_square_footage', 'lot_front_footage', 'depth_footage',
    'rm_status', 'dupe_num', 'price', 'owner_name2', '\'Feature\' AS type'
  ].join(', ')
  # columns returned internally for snail pdf render lookups
  address: [
    'owner_name', 'owner_name2', 'owner_street_address_num', 'owner_street_address_name', 'owner_street_address_unit',
    'owner_city', 'owner_state', 'street_address_num', 'street_address_name', 'street_address_unit', 'city', 'state',
    'zip', 'owner_zip'
  ].join(', ')
  parcel: ['geom_point_json'].concat(_parcel).join(', ')
  #cartodb will only save it as 0 / 1 so we might as well keep the size smaller with 0/1
  cartodb_parcel: ['0 as is_active', '0 as num_updates', ].concat(_parcel).join(', ')

  notes: _commonProjectCols.concat ['rm_property_id', 'geom_point_json', 'comments', 'text', 'title']

  project: ['id', 'auth_user_id', 'archived', 'sandbox', 'name', 'minPrice', 'maxPrice', 'beds', 'baths', 'sqft', 'properties_selected']

  user: ['username', 'password', 'first_name', 'last_name', 'email', 'cell_phone', 'work_phone', 'address_1', 'address_2', 'zip', 'city', 'parent_id']

  profile: ['id', 'auth_user_id', 'parent_auth_user_id', 'project_id', 'filters', 'map_toggles', 'map_position', 'map_results', 'favorites']

  drawnShapes: _commonProjectCols.concat ['geom_point_json', 'geom_polys_raw']

columns.all = "#{columns.filter}, #{columns.detail}"


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
    sql: "#{_ageOrDaysFromStartToNow(listingAge, beginDate)} #{operator} ?"
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
  tableFn()
  .where(whereClause)
  .whereNot(id:id)
  .count()
  .then singleRow
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
