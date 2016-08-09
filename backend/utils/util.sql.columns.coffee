tables = require '../config/tables'
_ = require 'lodash'

ageOrDaysFromStartToNow = (listingAge, beginDate) ->
  "COALESCE(#{listingAge}, now()::DATE - #{beginDate})"


#TODO: Move all of SQL Helpers columns into here as another sep PR.
basicColumns = do ->
  _parcel = [
    'rm_property_id', 'street_address_num', 'geometry',
    "'Feature' AS type",
    'fips_code', "'{}'::json AS properties"
  ]

  _commonProjectCols = ['id', 'auth_user_id', 'project_id']

  ret =
    # columns returned for filter requests
    filter: [
      'data_source_type',
      'data_source_id',
      'rm_property_id',
      'address',
      'geometry',
      'geometry_center',
      'owner_name',
      'owner_name_2',
      'year_built',
      'acres',
      'sqft_finished',
      'baths_total',
      "baths"
      'bedrooms',
      'price',
      'owner_address'
      'cdn_photo'
      'photo_count'
      'actual_photo_count'
      'status'
      'up_to_date'
    ].map((name)-> tables.finalized.combined.tableName + '.' + name).join(', ')

    parcel: ['geometry_center'].concat(_parcel).join(', ')

    #cartodb will only save it as 0 / 1 so we might as well keep the size smaller with 0/1
    cartodb_parcel: ['0 as is_active', '0 as num_updates', ].concat(_parcel).join(', ')

    notes: _commonProjectCols.concat ['rm_property_id', 'geometry_center', 'comments', 'text', 'title', 'rm_modified_time', 'rm_inserted_time']

    project: ['id', 'auth_user_id', 'archived', 'sandbox', 'name', 'minPrice', 'maxPrice', 'beds', 'baths',
      'sqft', 'status']

    user: ['username', 'password', 'first_name', 'last_name', 'email', 'cell_phone', 'work_phone',
      'address_1', 'address_2', 'zip', 'city', 'parent_id', 'cancel_email_hash',
      'stripe_customer_id', 'stripe_subscription_id',
      'email_validation_hash_update_time', 'email_validation_attempt',
      'email_validation_hash', 'email_is_valid']

    #all id, _id .. are not technically safe unless it is coming from session explicitly
    profile: ['id', 'auth_user_id', 'parent_auth_user_id', 'project_id', 'filters', 'map_toggles', 'can_edit',
      'map_position', 'map_results']

    drawnShapes: _commonProjectCols.concat ['geometry_center', 'geometry_raw', 'shape_extras',
      'area_name', 'area_details']

    creditCards: ['id', 'auth_user_id', 'token', 'last4', 'brand', 'country', 'exp_month', 'exp_year', 'last_charge_amount']

    mailCampaigns: ['id', 'auth_user_id', 'project_id', 'lob_batch_id', 'name', 'count', 'status', 'custom_content', 'content', 'template_type', 'submitted', 'sender_info', 'lob_content', 'recipients']

    mls: ['id', 'state', 'full_name', 'mls']

    all: ['rm_inserted_time', 'data_source_id', 'data_source_type', 'batch_id', 'up_to_date', 'active', 'change_history', 'prior_entries',
      'rm_property_id', 'fips_code', 'parcel_id', 'address', 'price', 'close_date', 'days_on_market', 'bedrooms', 'acres', 'sqft_finished', 'substatus',
      'status_display', 'owner_name', 'owner_name_2', 'geometry', 'geometry_center', 'geometry_raw', 'shared_groups', 'subscriber_groups', 'hidden_fields',
      'ungrouped_fields', 'discontinued_date', 'rm_raw_id', 'data_source_uuid', 'inserted', 'updated', 'update_source', 'owner_address', 'year_built',
      'property_type', 'photo_id', 'photo_count', 'photos', 'photo_last_mod_time',
      'actual_photo_count', 'cdn_photo', 'baths', 'baths_total', 'zoning', 'description', 'original_price', 'status'
    ]

    company: [ 'name', 'fax', 'phone', 'address_1', 'address_2', 'us_state_id', 'website_url', 'account_image_id',
      'city', 'zip'
    ]

    id: ['rm_property_id', 'data_source_type'] # `data_source_type` needed for finding "mls" or "county" category

  ret


safeFromQuery =
  profile: _.without basicColumns.profile, 'id', 'auth_user_id', 'parent_auth_user_id'

joinColumns = do ->
  permission: [
    "#{tables.auth.m2m_user_permission.tableName}.id as id"
    'user_id'
    'permission_id'
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
    # TODO REMOVE THIS LINE ONCE ALL REFERENCES TO user_id are removed
    # Most of our code base uses auth_user_id and auth_user_id is the correct query column name as well.
    # Not removing this now as there should be a specific ticket for this to have less chance of regressions.
    "#{tables.user.profile.tableName}.auth_user_id as user_id"
    "#{tables.user.profile.tableName}.auth_user_id as auth_user_id"
    "#{tables.user.profile.tableName}.parent_auth_user_id"
    "#{tables.user.profile.tableName}.can_edit"
    "#{tables.user.profile.tableName}.filters"
    "#{tables.user.profile.tableName}.map_toggles"
    "#{tables.user.profile.tableName}.map_position"
    "#{tables.user.profile.tableName}.map_results"
    "#{tables.user.profile.tableName}.project_id"
    "#{tables.user.profile.tableName}.rm_modified_time"
    "#{tables.user.profile.tableName}.favorites"

    "#{tables.user.project.tableName}.name"
    "#{tables.user.project.tableName}.archived"
    "#{tables.user.project.tableName}.sandbox"
    "#{tables.user.project.tableName}.minPrice"
    "#{tables.user.project.tableName}.maxPrice"
    "#{tables.user.project.tableName}.beds"
    "#{tables.user.project.tableName}.baths"
    "#{tables.user.project.tableName}.sqft"
    "#{tables.user.project.tableName}.pins"
  ]

  client: [
    "#{tables.user.profile.tableName}.id as id"
    "#{tables.user.profile.tableName}.auth_user_id as auth_user_id"
    "#{tables.user.profile.tableName}.parent_auth_user_id as parent_auth_user_id"
    "#{tables.user.profile.tableName}.project_id as project_id"
    "#{tables.user.profile.tableName}.can_edit as can_edit"
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
