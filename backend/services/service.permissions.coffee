_ = require "lodash"
memoize = require "memoizee"
Promise = require "bluebird"

config = require "../config/config"
logger = require '../config/logger'
User = require "../models/model.user"
Permission = require "../models/model.permission"
Group = require "../models/model.group"


hashifyPermissions = (hash, permission) ->
  hash[permission.codename] = true;
  return hash


# returns: a hash of codenames to truthy values
getPermissionsForGroupId = (id) ->
  Group.forge(id: id).fetch(withRelated: ['permissions'], require: true)
  .then (group) ->
    # we want to reformat this data as a hash of codenames to truthy values
    permissionsHash = _.reduce(group.related("permissions").toJSON(), hashifyPermissions, {})
    logger.info("permissions loaded for groupid #{id}")
    logger.debug(JSON.stringify(permissionsHash, null, 2))
    return permissionsHash
  .catch (err) ->
    logger.error "error loading permissions for groupid #{id}: #{err}"
    Promise.reject(err)
    
# wrap function in a caching memoizer
getPermissionsForGroupId = memoize(getPermissionsForGroupId, { maxAge: config.DB_CACHE_TIMES.SLOW_REFRESH, prefetch: .1 })


# returns: a hash of codenames to truthy values
getPermissionsForUserId = (id) ->
  User.forge(id: id).fetch(withRelated: ['permissions', 'groups'], require: true)
  .then (user) ->
    if user.get('is_superuser')
      # just give them all the permissions
      Permission.fetchAll()
      .then (permissions) -> return permissions.toJSON()
      .reduce(hashifyPermissions, {})
      .then (permissionsHash) ->
        logger.debug "superuser permissions loaded for userid #{id}"
        return permissionsHash
    else
      # grab the permissions on the user
      userPermissions = _.reduce(user.related('permissions').toJSON(), hashifyPermissions, {})
      logger.debug "user permissions loaded for userid: #{id}"
      # grab the permissions on each group
      groupPermissions = user.related('groups')
      .mapThen((group) -> return group.id)
      .map(getPermissionsForGroupId)
      .then (groupPermissionsArray) -> 
        logger.debug "group permissions loaded for userid #{id}"
        return groupPermissionsArray
      # merge them all together
      return Promise.join userPermissions, groupPermissions, (userPermissions, groupPermissions) ->
        return _.merge(userPermissions, groupPermissions...)
  .then (permissionsHash) ->
    logger.debug "all permissions loaded for userid #{id}:"
    logger.debug JSON.stringify(permissionsHash, null, 2)
    return permissionsHash
  .catch (err) ->
    logger.error "error loading permissions for userid #{id}"
    Promise.reject(err)
# we're not going to memoize this one because we're caching the results on the
# session, and want new logins to get new permissions instantly

module.exports =
  getPermissionsForGroupId: getPermissionsForGroupId
  getPermissionsForUserId: getPermissionsForUserId
