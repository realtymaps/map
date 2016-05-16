_ = require 'lodash'
memoize = require 'memoizee'
Promise = require 'bluebird'

config = require '../config/config'
logger = require '../config/logger'
tables = require '../config/tables'
dbs = require '../config/dbs'

{expectSingleRow} =  require '../utils/util.sql.helpers'

hashifyPermissions = (hash, permission) ->
  hash[permission.codename] = true
  return hash

hashifyGroups = (hash, group) ->
  hash[group.name] = true
  return hash


# returns: Permission primary key ID for the given permission codename
getPermissionForCodename = (codename) ->
  tables.auth.permission()
  .where
    codename: codename
  .then (rows) ->
    expectSingleRow(rows)
  .then (row) ->
    logger.info("permission found for codename #{codename}")
    Promise.resolve(row)
  .catch (err) ->
    logger.error "error loading permission for codename #{codename}: #{err}"
    Promise.reject(err)

# returns: a hash of codenames to truthy values
getPermissionsForGroupId = (id) ->
  tables.auth.permission()
  .whereExists () ->
    tables.auth.m2m_group_permission(transaction: this)
    .where
      group_id: id
      permission_id: dbs.get('main').raw("#{tables.auth.permission.tableName}.id")
  .then (permissions=[]) ->
    # we want to reformat this data as a hash of codenames to truthy values
    logger.info("permissions loaded for groupid #{id}")
    _.reduce(permissions, hashifyPermissions, {})
  .catch (err) ->
    logger.error "error loading permissions for groupid #{id}: #{err}"
    Promise.reject(err)

# returns: a hash of codenames to truthy values
getPermissionsForUserId = (id) ->
  tables.auth.user()
  .where(id: id)
  .then (user) ->
    if user[0].is_superuser
      # just give them all the permissions
      tables.auth.permission()
      .select()
      .then (permissions=[]) ->
        _.reduce(permissions, hashifyPermissions, {})
    else
      # grab the permissions on the user
      userPermissionsPromise = tables.auth.permission()
      .whereExists () ->
        tables.auth.m2m_user_permission(transaction: this)
        .where
          user_id: id
          permission_id: dbs.get('main').raw("#{tables.auth.permission.tableName}.id")
      .then (permissions=[]) ->
        _.reduce(permissions, hashifyPermissions, {})
      # grab the permissions on each group
      groupPermissionsPromise = tables.auth.m2m_user_group()
      .select('group_id')
      .where(user_id: id)
      .then (groups=[]) ->
        _.map _.pluck(groups, 'group_id'), getPermissionsForGroupId
      # merge them all together
      Promise.join userPermissionsPromise, groupPermissionsPromise, (userPermissions, groupPermissions) ->
        _.merge(userPermissions, groupPermissions...)
  .catch (err) ->
    logger.error "error loading permissions for userid #{id}"
    return Promise.reject(err)
# we're not going to memoize this one because we're caching the results on the
# session, and want new logins to get new permissions instantly


# returns: a hash of group names to truthy values
getGroupsForUserId = (id) ->
  tables.auth.group()
  .whereExists () ->
    tables.auth.m2m_user_group(transaction: this)
    .where
      user_id: id
      group_id: dbs.get('main').raw("#{tables.auth.group.tableName}.id")
  .then (groups=[]) ->
    _.reduce(groups, hashifyGroups, {})
# we're not going to memoize this one because we're caching the results on the
# session, and want new logins to get new groups instantly

setPermissionForUserId = ({user_id, permission_id, transaction = null}) ->
  tables.auth.m2m_user_permission(transaction: transaction)
  .count()
  .where user_id: user_id, permission_id: permission_id
  .then ([result]) ->
    if Number(result.count) == 0
      tables.auth.m2m_user_permission(transaction: transaction)
      .insert user_id: user_id, permission_id: permission_id


module.exports =
  getPermissionForCodename: getPermissionForCodename
  getPermissionsForGroupId: memoize(getPermissionsForGroupId, primitive: true, maxAge: 10*60*1000, preFetch: .1)
  getPermissionsForUserId: getPermissionsForUserId
  getGroupsForUserId: getGroupsForUserId
  setPermissionForUserId: setPermissionForUserId
