querystring = require 'querystring'
Promise = require 'bluebird'
_ = require 'lodash'
crypto = require 'crypto'
base64url = require 'base64url'

logger = require '../config/logger'
config = require '../config/config'
userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'
routes = require '../../common/config/routes'
userUtils = require '../routeUtils/userUtils'


getSessionUser = (req) -> Promise.try () ->
  if not req.session.userid
    return Promise.resolve(false)
  return userService.getUser(id: req.session.userid).catch (err) -> return false

    
module.exports = {

  # this function gets used as app-wide middleware, so assume it will have run
  # before any route gets called
  setSessionCredentials: (req, res, next) ->
    getSessionUser(req)
      .then (user) ->
        # set the user on the request
        req.user = user
        
        if req.user and not req.session.permissions
          # something bad must have happened while loading permissions, try to recover
          logger.debug "trying to set permissions on session for user: #{req.user.username}"
          return permissionsService.getPermissionsForUserId(req.user.id)
            .then (permissionsHash) ->
              logger.debug "permissions loaded on session for user: #{req.user.username}"
              req.session.permissions = permissionsHash
      .then () ->
        next()
      .catch (err) ->
        logger.debug "error while setting session user on request"
        next(err)
        
  checkSessionSecurity: (req res, next) ->
    


# route-specific middleware that requires a login, and either responds with
# a 401 or a login redirect on failure, based on the options.
#   options:
#     redirectOnFail: whether to redirect to the login page, default false
  requireLogin: (options = {}) ->
    defaultOptions =
      redirectOnFail: false
    options = _.merge(defaultOptions, options)
    return (req, res, next) -> Promise.try () ->
      if not req.user
        if options.redirectOnFail
          return res.redirect("#{routes.logIn}?#{querystring.stringify(next: req.originalUrl)}")
        else
          return res.status(401).send("Please login to access this URI.")
      return process.nextTick(next)

# route-specific middleware that requires permissions set on the session,
# and either responds with a 401 or a logout redirect on failure, based on
# the options passed:
#   permissions:
#     parameter specifying what permission(s) the user needs in order to
#     access the given route; can either be a single string, or an object
#     with either "any" or "all" as a key and an array of strings as a value  
#   options:
#     logoutOnFail: whether to redirect to the logout page, default false
  requirePermissions: (permissions, options = {}) ->
    defaultOptions =
      logoutOnFail: false
    options = _.merge(defaultOptions, options)
    if typeof(permissions) is "string"
      permissions = { any: [permissions] }
    # don't allow strange inputs
    if permissions.all and permissions.any
      throw new Error("Both 'all' and 'any' permission semantics may not be used on the same route.")
    if not permissions.all and not permissions.any
      throw new Error("No permissions specified.")
    return (req, res, next) -> Promise.try () ->
      granted = false
      if req.session.permissions
        if permissions.any
          # we only need one of the permissions in the array
          for permission in permissions.any
            if req.session.permissions[permission]
              logger.debug "access allowed because user has '#{permission}' permission"
              granted = true
              break;
        else if permissions.all
          # we need all the permissions in the array
          granted = true
          for permission in permissions.all
            if not req.session.permissions[permission]
              logger.debug "access denied because user lacks '#{permission}' permission"
              granted = false
              break
      if not granted
        logger.warn "access denied to username #{req.user.username} for URI: #{req.originalUrl}"
        if options.logoutOnFail
          return userUtils.doLogout(req, res, next)
        else
          return res.status(401).send("You do not have permission to access this URI.")
      return process.nextTick(next)

  # function to generate a 64-char session UUID, much larger than the default
  # which is 24-char.  We don't make this a config option here because the
  # session_security.session_id column is varchar(64); that table would need
  # to be migrated if this value is increased
  genUUID: () ->
    # increase security by throwing away some random bytes
    crypto.pseudoRandomBytes(8)
    # 48 bytes is 64 characters after base64 encoding
    return base64url(crypto.pseudoRandomBytes(48))
}
