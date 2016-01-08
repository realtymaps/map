Promise = require 'bluebird'

logger = require '../config/logger'
userSessionService = require '../services/service.userSession'
permissionsService = require '../services/service.permissions'

# caches permission and group membership values on the user session; we could
# get into unexpected states if those values change during a session, so we
# cache them instead of refreshing.  This means for certain kinds of changes
# to a user account, we will either need to explicitly refresh these values,
# or we'll need to log out the user and let them get refreshed when they log
# back in.
cacheUserValues = (req, reload = {}) ->
  promises = []
  if not req.session.permissions or reload?.permissions
    logger.debug 'req.session.permissions'
    permissionsPromise = permissionsService.getPermissionsForUserId(req.user.id)
    .then (permissionsHash) ->
      req.session.permissions = permissionsHash
    promises.push permissionsPromise
  if not req.session.groups or reload?.groups
    logger.debug 'req.session.groups'
    groupsPromise = permissionsService.getGroupsForUserId(req.user.id)
    .then (groupsHash) ->
      req.session.groups = groupsHash
    promises.push groupsPromise
  if not req.session.profiles or reload?.profiles
    logger.debug "req.session.profiles: #{req.user.id}"
    profilesPromise = userSessionService.getProfiles(req.user.id)
    .then (profiles) ->
      logger.debug 'userSessionService.getProfiles.then'
      req.session.profiles = profiles
      # logger.debug profiles
    promises.push profilesPromise
  return Promise.all(promises)
  #.then () ->
  #  logger.debug "all user values cached for user: #{req.user.username}"
  .catch (err) ->
    logger.error "error caching user values for user: #{req.user.username}"
    Promise.reject(err)

module.exports =
  cacheUserValues: cacheUserValues
