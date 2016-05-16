tables = require '../config/tables'
_ = require 'lodash'

ageOrDaysFromStartToNow = (listingAge, beginDate) ->
  "COALESCE(#{listingAge}, now()::DATE - #{beginDate})"


#TODO: Move all of SQL Helpers columns into here as another sep PR.
basicColumns = do ->
  _parcel = [
    'rm_property_id', 'street_address_num', 'geom_polys_json AS geometry',
    '\'Feature\' AS type',
    'fips_code', '\'{}\'::json AS properties'
  ]

  _commonProjectCols = ['id', 'auth_user_id', 'project_id']

  ret =
    # columns returned for filter requests
    filter: [
      'rm_property_id', 'street_address_num', 'street_address_name', 'street_address_unit', 'geom_polys_json AS geometry',
      'geom_point_json', 'rm_status', 'owner_name', 'owner_name2', 'year_built', 'acres', 'finished_sqft', 'baths_full',
      'baths_half', 'baths_total', 'bedrooms', 'price', 'assessed_value', 'city', 'state', 'zip',
      'owner_street_address_num', 'owner_street_address_name', 'owner_street_address_unit', 'owner_city', 'owner_state',
      'owner_zip'
    ].map((name)-> tables.property.propertyDetails.tableName + '.' + name).join(', ')
    filterCombined: [
      'rm_property_id',
      'address',
      'geometry',
      'geometry_center AS geom_point_json',
      'status AS rm_status',
      'owner_name',
      'owner_name_2 as owner_name2',
      'year_built',
      'acres',
      'sqft_finished as finished_sqft',
      'baths_total',
      "baths"
      'bedrooms',
      'price',
      'owner_address'
      'cdn_photo'
      'photo_count'
    ].map((name)-> tables.property.combined.tableName + '.' + name)
    .concat [
      "floor(#{tables.property.combined.tableName}.baths_total)::int as baths_full",
      "(case when (#{tables.property.combined.tableName}.baths_total::int - #{tables.property.combined.tableName}.baths_total) > 0 then 1 else 0 end) as baths_half"
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
      "#{ageOrDaysFromStartToNow('listing_age_days', 'listing_start_date')} AS listing_age",
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
      'sewer', 'assessed_value', 'assessed_year', 'property_information', 'land_square_footage', 'lot_front_footage',
      'depth_footage', 'rm_status', 'dupe_num', 'price', 'owner_name2', '\'Feature\' AS type'
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

    notes: _commonProjectCols.concat ['rm_property_id', 'geom_point_json', 'comments', 'text', 'title', 'rm_modified_time', 'rm_inserted_time']

    project: ['id', 'auth_user_id', 'archived', 'sandbox', 'name', 'minPrice', 'maxPrice', 'beds', 'baths',
      'sqft', 'properties_selected', 'status']

    user: ['username', 'password', 'first_name', 'last_name', 'email', 'cell_phone', 'work_phone',
      'address_1', 'address_2', 'zip', 'city', 'parent_id', 'cancel_email_hash',
      'stripe_customer_id', 'stripe_subscription_id',
      'email_validation_hash_update_time', 'email_validation_attempt',
      'email_validation_hash', 'email_is_valid']

    #all id, _id .. are not technically safe unless it is coming from session explicitly
    profile: ['id', 'auth_user_id', 'parent_auth_user_id', 'project_id', 'filters', 'map_toggles',
      'map_position', 'map_results', 'favorites']

    drawnShapes: _commonProjectCols.concat ['geom_point_json', 'geom_polys_raw', 'shape_extras',
      'neighbourhood_name', 'neighbourhood_details']

    creditCards: ['id', 'auth_user_id', 'token', 'last4', 'brand', 'country', 'exp_month', 'exp_year', 'last_charge_amount']

    mailCampaigns: ['id', 'auth_user_id', 'project_id', 'lob_batch_id', 'name', 'count', 'status', 'content', 'template_type', 'submitted', 'sender_info', 'lob_content', 'recipients']

    mls: ['id', 'state', 'full_name', 'mls']

    mls_disclaimer: ['config_mls.dcma_contact_name', 'config_mls.dcma_contact_address', 'config_mls.formal_name'
      'disclaimer_text', 'disclaimer_logo']

    new_all: '*'

    new_all_explicit: ['rm_inserted_time', 'data_source_id', 'data_source_type', 'batch_id', 'up_to_date', 'active', 'change_history', 'prior_entries,
      rm_property_id', 'fips_code', 'parcel_id', 'address', 'price', 'close_date', 'days_on_market', 'bedrooms', 'acres', 'sqft_finished', 'status', 'substatus,
      status_display', 'owner_name', 'owner_name_2', 'geometry', 'geometry_center', 'geometry_raw', 'shared_groups', 'subscriber_groups', 'hidden_fields,
      ungrouped_fields', 'discontinued_date', 'rm_raw_id', 'data_source_uuid', 'inserted', 'updated', 'update_source', 'owner_address', 'year_built,
      property_type', 'photo_id', 'photo_count', 'photos', 'photo_import_error', 'photo_last_mod_time', 'photo_download_last_mod_time,
      actual_photo_count', 'cdn_photo', 'baths', 'baths_total']

    company: [ 'name', 'fax', 'phone', 'address_1', 'address_2', 'us_state_id', 'website_url', 'account_image_id',
      'city', 'zip'
    ]

  ret.all = "#{ret.filter}, #{ret.detail}"
  ret.detail_with_disclaimer = "#{ret.new_all_explicit}, #{ret.mls_disclaimer}"
  ret


safeFromQuery =
  profile: _.without basicColumns.profile, 'id', 'auth_user_id', 'parent_auth_user_id'

joinColumns = do ->
  permission: [
    "#{tables.auth.m2m_user_permission.tableName}.id as id"
    'user_id'
    'permission_id'
    'content_type_id'
    'name'
    'codename'
  ]

  groups: [
    "#{tables.auth.m2m_user_group.tableName}.id as id"
    'user_id'
    'group_id'
    'name'
  ]

  profile: [
    "#{tables.user.profile.tableName}.id as id"
    "#{tables.user.profile.tableName}.auth_user_id as user_id"
    "#{tables.user.profile.tableName}.parent_auth_user_id"
    "#{tables.user.profile.tableName}.filters"
    "#{tables.user.profile.tableName}.map_toggles"
    "#{tables.user.profile.tableName}.map_position"
    "#{tables.user.profile.tableName}.map_results"
    "#{tables.user.profile.tableName}.favorites"
    "#{tables.user.profile.tableName}.project_id"
    "#{tables.user.profile.tableName}.rm_modified_time"

    "#{tables.user.project.tableName}.name"
    "#{tables.user.project.tableName}.archived"
    "#{tables.user.project.tableName}.sandbox"
    "#{tables.user.project.tableName}.minPrice"
    "#{tables.user.project.tableName}.maxPrice"
    "#{tables.user.project.tableName}.beds"
    "#{tables.user.project.tableName}.baths"
    "#{tables.user.project.tableName}.sqft"
    "#{tables.user.project.tableName}.properties_selected"
  ]

  client: [
    "#{tables.user.profile.tableName}.id as id"
    "#{tables.user.profile.tableName}.auth_user_id as auth_user_id"
    "#{tables.user.profile.tableName}.parent_auth_user_id as parent_auth_user_id"
    "#{tables.user.profile.tableName}.project_id as project_id"
    "#{tables.user.profile.tableName}.favorites as favorites"

    "#{tables.auth.user.tableName}.email as email"
    "#{tables.auth.user.tableName}.first_name as first_name"
    "#{tables.auth.user.tableName}.last_name as last_name"
    "#{tables.auth.user.tableName}.username as username"
    "#{tables.auth.user.tableName}.address_1 as address_1"
    "#{tables.auth.user.tableName}.address_2 as address_2"
    "#{tables.auth.user.tableName}.city as city"
    "#{tables.auth.user.tableName}.zip as zip"
    "#{tables.auth.user.tableName}.us_state_id as us_state_id"
    "#{tables.auth.user.tableName}.cell_phone as cell_phone"
    "#{tables.auth.user.tableName}.work_phone as work_phone"
    "#{tables.auth.user.tableName}.parent_id as parent_id"
  ]

  notes: basicColumns.notes.map (col) ->  "#{tables.user.notes.tableName}.#{col} as #{col}"

  drawnShapes: basicColumns.drawnShapes.map (col) ->  "#{tables.user.drawnShapes.tableName}.#{col} as #{col}"

joinColumnNames = do ->
  _.mapValues joinColumns, (v) ->
    obj = {}
    for str in v
      #remove as portion
      val = str.split(' as ')[0]
      val = if !val then str else val
      #get basic name
      split = val.split('.')
      key = if split?.length > 1 then split[1] else val
      #obj.basicName = complex explicit join name
      #clients.email = "{tables.auth.user.tableName}.email"
      obj[key] = val
    obj

module.exports = {
  basicColumns
  safeFromQuery
  joinColumns
  joinColumnNames
  ageOrDaysFromStartToNow
}
