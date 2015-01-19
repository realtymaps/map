memoize = require 'memoizee'


_whereRawSafe = (query, rawSafe) ->
  query.whereRaw rawSafe.sql, rawSafe.bindings
  
_orWhereRawSafe = (query, rawSafe) ->
  query.orWhere ()-> _whereRawSafe(@, rawSafe)


_ageOrDaysFromStartToNow = (listingAge, beginDate) ->
  "COALESCE(#{listingAge}, now()::DATE - #{beginDate})"


_columns =
  # columns returned for filter requests
  filter: [
    'rm_property_id', 'street_address_num', 'street_address_name', 'street_address_unit', 'geom_polys_json',
    'geom_point_json', 'rm_status', 'owner_name', 'owner_name2', 'year_built', 'acres', 'finished_sqft', 'baths_full',
    'baths_half', 'baths_total', 'bedrooms', 'price', 'assessed_value'
  ].join(', ')
  # columns returned for additional detail results
  detail: [
    'owner_street_address_num', 'owner_street_address_name', 'owner_street_address_unit', 'owner_city', 'owner_state',
    'owner_zip', 'annual_tax', 'tax_desc', 'property_indication_category', 'property_indication_name', 'zoning',
    'year_modified', 'ask_price', 'prior_sale_price', 'original_price', 'close_price', 'mortgage_amount',
    'listing_start_date', 'close_date', 'city', 'state', 'zip', 'mortgage_date', 'recording_date', 'title_company_name',
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

  _whereRawSafe: _whereRawSafe
  _orWhereRawSafe: _orWhereRawSafe
  
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
