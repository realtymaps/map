Promise = require 'bluebird'
querystring = require 'querystring'

logger = require '../config/logger'
config = require '../config/config'

httpStatus = require '../../common/utils/httpStatus'
userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'
sessionSecurityService = require '../services/service.sessionSecurity'


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
  return Promise.all(promises)
  .then () ->
    logger.debug "all user values cached for user: #{req.user.username}"
  .catch (err) ->
    logger.error "error caching user values for user: #{req.user.username}"
    Promise.reject(err)

    
# handle login authentication, and do all the things needed for a new login session
doLogin = (req, res, next) -> Promise.try () ->
  if req.user
    # someone is logging in over an existing session...  shouldn't normally happen, but we'll deal
    logger.debug "attempting to log user out (someone is logging in): #{req.user.username}"
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.user = null
      req.session.regenerateAsync()
  else
    promise = Promise.resolve()

  promise.then () ->
    logger.debug "attempting to do login for username: #{req.body.username}"
    userService.verifyPassword(req.body.username, req.body.password)
  .catch (err) ->
    logger.debug "failed authentication: #{err}"
    return false
  .then (user) ->
    if not user
      return next(status: httpStatus.UNAUTHORIZED, message: {error: "Username and/or password does not match our records."})
    else
      req.user = user
      req.session.userid = user.id
      module.exports.cacheUserValues(req)
      .then () ->
        req.session.saveAsync()
      .then () ->
        sessionSecurityService.ensureSessionCount(req)
      .then () ->
        sessionSecurityService.createNewSeries(req, res, !!req.body.remember_me)
      .then () ->
        identity =
          permissions: req.session.permissions
          groups: req.session.groups
        return res.json(identity: identity)
  .catch (err) ->
    logger.error "unexpected error during doLogin(): #{err}"
    next(err)


# everything we need to do for a logout gets encapsulated here
doLogout = (req, res, next) -> Promise.try () ->
  if req.user
    logger.debug "attempting to log user out: #{req.user.username}"
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.session.destroyAsync()
  else
    promise = Promise.resolve()
  promise.then () ->
    return res.json(identity: null)
  .catch (err) ->
    logger.error "error logging out user: #{err}"
    next(err)


module.exports =
  cacheUserValues: cacheUserValues
  doLogin: doLogin
  doLogout: doLogout
 