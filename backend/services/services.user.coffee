_ = require 'lodash'
logger = require '../config/logger'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'

toInit = {}
_.extend toInit, _.pick tables.lookup, [
  'usStates'
  'accountUseTypes'
]
_.extend toInit, _.pick tables.auth, [
  'group'
  'permission'
  'm2m_group_permission'
  'm2m_user_permission'
  'm2m_user_group'
]
_.extend toInit, _.pick tables.user, [
  'profile'
  'project'
  'company'
  'accountImages'
  'drawnShapes'
]

manualInits = {
  notes: tables.user
}

for tableName, tableVal of manualInits
  toInit[tableName] = () ->
    sqlHelpers.select(tableVal[tableName](), tableName)
  toInit[tableName].tableName = tableVal[tableName].tableName #keep same interface

{crud, ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'

for key, val of toInit
  module.exports[key] = crud(val)

permissionCols = [
  "#{tables.auth.m2m_user_permission.tableName}.id as id"
  'user_id'
  'permission_id'
  'content_type_id'
  'name'
  'codename'
]

groupsCols = [
  "#{tables.auth.m2m_user_group.tableName}.id as id"
  'user_id'
  'group_id'
  'name'
]

profileCols = [
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

clientCols = [
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

notesCols = sqlHelpers.columns.notes.map (col) ->  "#{tables.user.notes.tableName}.#{col} as #{col}"

drawnShapesCols = sqlHelpers.columns.drawnShapes.map (col) ->  "#{tables.user.drawnShapes.tableName}.#{col} as #{col}"

class UserCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  init: () =>
    # taking care of inits here fore internal svcs so they can be overriden
    logger.debug 'INIT UserCrud Service'
    @permissions = thenableHasManyCrud(tables.auth.permission, permissionCols,
      module.exports.m2m_user_permission, 'permission_id', undefined, "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @groups = thenableHasManyCrud(tables.auth.group, groupsCols,
      module.exports.m2m_user_group, 'group_id', undefined, "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @profiles = thenableHasManyCrud(tables.user.project, profileCols,
      module.exports.profile, "#{tables.user.profile.tableName}.project_id", undefined, "#{tables.user.profile.tableName}.id").init(arguments...)

    @clients = thenableHasManyCrud(tables.auth.user, clientCols,
      module.exports.profile, undefined, undefined, "#{tables.user.profile.tableName}.id").init(arguments...)
    super(arguments...)

module.exports.user = new UserCrud(tables.auth.user).init(false)

class ProjectCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  # clients: thenableHasManyCrud(tables.auth.user, clientCols, module.exports.profile, 'project_id',
  #   undefined, clientCols[0]).init(false)
  #(dbFn, @rootCols, @joinCrud, joinIdStr, rootIdStr, idKey) ->
  notes: thenableHasManyCrud(tables.user.notes, notesCols, module.exports.notes, 'project_id',
    undefined, notesCols[0]).init(false)

  drawnShapes: thenableHasManyCrud(tables.user.drawnShapes, drawnShapesCols,
    module.exports.drawnShapes, 'project_id', undefined, drawnShapesCols[0]).init(false)

#temporary to not conflict with project
module.exports.Project = new ProjectCrud(tables.user.project).init(true)
