memoize = require 'memoizee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'



# MARGIN IS THE PERCENT THE BOUNDS ARE EXPANDED TO GRAB Extra Data around the view
_MARGIN = .25

_flattenLonLatImpl = (all, next) ->
  all.bindings.push(next.lon, next.lat)
  all.markers += ", ?, ?"
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


_columns =
  # columns returned for filter requests
  filter: [
    'rm_property_id', 'street_address_num', 'street_address_name', 'street_address_unit', 'geom_polys_json',
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
  # columns returned internally for snail pdf render lookups
  address: [
    'owner_name', 'owner_name2', 'owner_street_address_num', 'owner_street_address_name', 'owner_street_address_unit',
    'owner_city', 'owner_state', 'street_address_num', 'street_address_name', 'street_address_unit', 'city', 'state',
    'zip', 'owner_zip'
  ].join(', ')
  '*': '*'
_columns.all = "#{_columns.filter}, #{_columns.detail}"


module.exports =

  between: (query, column, min, max) ->
    if min and max
      query.whereBetween(column, [min, max])
    else if min
      query.where(column, '>=', min)
    else if max
      query.where(column, '<=', max)
  
  tableName: memoize (model) ->
    model.query()._single.table

  ageOrDaysFromStartToNow: (query, listingAge, beginDate, operator, val) ->
    query.whereRawSafe query,
      sql: "#{_ageOrDaysFromStartToNow(listingAge, beginDate)} #{operator} ?"
      bindings: [ val ]

  orderByDistanceFromPoint: (query, column, point) ->
    # order by distance from point
    # http://boundlessgeo.com/2011/09/indexed-nearest-neighbour-search-in-postgis/
    #geom <-> st_setsrid(st_makepoint(-90,40),4326)
    _orderByRawSafe query,
      sql: "#{column} <-> st_setsrid(st_makepoint(?,?),#{coordSys.UTM})"
      bindings: [point.longitude, point.latitude]

  whereIn: (query, column, values) ->
    # this logic is necessary to avoid SQL parse errors
    if values.length == 1
      query.where(column, values[0])
    else
      query.whereIn(column, values)

  allPatternsInAnyColumn: (query, patterns, columns) ->
    patterns.forEach (pattern) ->
      query.where () ->
        subquery = @
        columns.forEach (column) ->
          _orWhereRawSafe subquery,
            sql: "#{column} ~* ?"
            bindings: [ pattern ]

  select: (knex, which, passedFilters) ->
    extra = ''
    if passedFilters?
      extra = ", #{passedFilters} as \"passedFilters\""
    knex.select(knex.raw(_columns[which]+extra))


  whereInBounds: (query, column, bounds) ->
    results = {}
    if bounds.length > 2
      # it must be a user-specified boundary
      boundsFlattened = _flattenLonLat(bounds)
      results.sql = "ST_WITHIN(#{column}, ST_GeomFromText(MULTIPOLYGON(((#{boundsFlattened.markers}))), #{coordSys.UTM}))"
      results.bindings = boundsFlattened.bindings
    else
      # it's the whole map, so let's put a margin on each side
      minLon = Math.min(bounds[0].lon, bounds[1].lon)
      maxLon = Math.max(bounds[0].lon, bounds[1].lon)
      marginLon = (maxLon - minLon)*_MARGIN
      minLat = Math.min(bounds[0].lat, bounds[1].lat)
      maxLat = Math.max(bounds[0].lat, bounds[1].lat)
      marginLat = (maxLat - minLat)*_MARGIN

      results.sql = "#{column} && ST_MakeEnvelope(?, ?, ?, ?, #{coordSys.UTM})"
      results.bindings = [ minLon-marginLon, minLat-marginLat, maxLon+marginLon, maxLat+marginLat ]
    _whereRawSafe query, results
