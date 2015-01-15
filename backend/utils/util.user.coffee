Promise = require 'bluebird'

logger = require '../config/logger'
userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'

# caches permission and group membership values on the user session; we could
# get into unexpected states if those values change during a session, so we
# cache them instead of refreshing.  This means for certain kinds of changes
# to a user account, we will either need to explicitly refresh these values,
# or we'll need to log out the user and let them get refreshed when they log
# back in.
cacheUserValues = (req) ->
  promises = []
  if not req.session.permissions
    permissionsPromise = permissionsService.getPermissionsForUserId(req.user.id)
    .then (permissionsHash) ->
      req.session.permissions = permissionsHash
    promises.push permissionsPromise
  if not req.session.groups
    groupsPromise = permissionsService.getGroupsForUserId(req.user.id)
    .then (groupsHash) ->
      req.session.groups = groupsHash
    promises.push groupsPromise
  if not req.session.state
    statePromise = userService.getUserState(req.user.id)
    .then (state) ->
      req.session.state = state
    promises.push statePromise
  return Promise.all(promises)
  #.then () ->
  #  logger.debug "all user values cached for user: #{req.user.username}"
  .catch (err) ->
    logger.error "error caching user values for user: #{req.user.username}"
    Promise.reject(err)

module.exports =
  cacheUserValues: cacheUserValues
