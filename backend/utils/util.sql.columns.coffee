sqlHelpers = require './util.sql.helpers'
tables = require '../config/tables'
_ = require 'lodash'

#TODO: Move all of SQL Helpers columns into here as another sep PR.
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
    "#{tables.user.profile.tableName}.project_id"

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

  notes: sqlHelpers.columns.notes.map (col) ->  "#{tables.user.notes.tableName}.#{col} as #{col}"

  drawnShapes: sqlHelpers.columns.drawnShapes.map (col) ->  "#{tables.user.drawnShapes.tableName}.#{col} as #{col}"

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

module.exports =
  joinColumns: joinColumns
  joinColumnNames: joinColumnNames
