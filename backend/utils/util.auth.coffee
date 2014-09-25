querystring = require 'querystring'
Promise = require 'bluebird'
_ = require 'lodash'

logger = require '../config/logger'
config = require '../config/config'
userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'
sessionSecurityService = require '../services/service.sessionSecurity'
routes = require '../../common/config/routes'
userUtils = require '../utils/util.user'


getSessionUser = (req) -> Promise.try () ->
  if not req.session.userid
    return Promise.resolve(false)
  return userService.getUser(id: req.session.userid)
  .catch (err) ->
    return false

    
module.exports = {

  # this function gets used as app-wide middleware, so assume it will have run
  # before any route gets called
  setSessionCredentials: (req, res) ->
    getSessionUser(req).then (user) ->
      # set the user on the request
      req.user = user
      if req.user
        return userUtils.cacheUserValues(req)
    .catch (err) ->
      logger.error "error while setting session data on request"
      Promise.reject(err)
        
  checkSessionSecurity: (req, res) ->
    Promise.resolve()
    .catch (err) ->
      logger.debug "error doing session security checks: #{err}"
      Promise.reject(err)


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
              break
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
}
