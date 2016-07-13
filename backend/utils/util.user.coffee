Promise = require 'bluebird'

logger = require '../config/logger'
profileSvc = require '../services/service.profiles'
permissionsService = require '../services/service.permissions'

# tests subscription status of the (if active) req.session
# This is leveraged in middleware, but can be used in route code for business logic needs
isSubscriber = (req) ->
  return req?.session?.subscription? and req?.session?.subscription != 'canceled' and req?.session?.subscription != 'unpaid'

# caches permission and group membership values on the user session; we could
# get into unexpected states if those values change during a session, so we
# cache them instead of refreshing.  This means for certain kinds of changes
# to a user account, we will either need to explicitly refresh these values,
# or we'll need to log out the user and let them get refreshed when they log
# back in.
cacheUserValues = (req, reload = {}) ->

  if !req.session.permissions or reload?.permissions
    logger.debug 'req.session.permissions'
    permissionsPromise = permissionsService.getPermissionsForUserId(req.user.id)
    .then (permissionsHash) ->
      req.session.permissions = permissionsHash

  if !req.session.groups or reload?.groups
    logger.debug 'req.session.groups'
    groupsPromise = permissionsService.getGroupsForUserId(req.user.id)
    .then (groupsHash) ->
      req.session.groups = groupsHash


  if !req.session.profiles or reload?.profiles
    logger.debug "req.session.profiles: #{req.user.id}"

    # if user is subscriber, use service endpoint that includes sandbox creation and display
    if isSubscriber(req)
      profilesPromise = profileSvc.getProfiles req.user.id

    # user is a client, and unallowed to deal with sandboxes
    else
      profilesPromise = profileSvc.getClientProfiles req.user.id

    profilesPromise = profilesPromise
    .then (profiles) ->
      logger.debug 'profileSvc.getProfiles.then'
      req.session.profiles = profiles


  Promise.all([permissionsPromise, groupsPromise, profilesPromise])
  .catch (err) ->
    logger.error "error caching user values for user: #{req.user.username}"
    Promise.reject(err)

module.exports =
  cacheUserValues: cacheUserValues
  isSubscriber: isSubscriber
