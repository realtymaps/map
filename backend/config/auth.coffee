querystring = require 'querystring'
Promise = require 'bluebird'
_ = require 'lodash'

logger = require '../config/logger'
config = require '../config/config'
userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'


getSessionUser = (req) -> Promise.try () ->
  if not req.session.userid
    return Promise.resolve(false)
  return userService.getUser(id: req.session.userid).catch (err) -> return false

    
doLoginRedirect = (req, res) -> Promise.try () ->
  if req.query.next
    return res.redirect(req.query.next)
  else
    return res.redirect(config.DEFAULT_LANDING_URL)


module.exports = {

  setSessionCredentials: (req, res, next) ->
    getSessionUser(req)
      .then (user) ->
        # set the user on the request
        req.user = user
        if user and not req.session.permissions
          # something bad must have happened while loading permissions, try to recover
          logger.debug "trying to set permissions on session for user: #{user.username}"
          return permissionsService.getPermissionsForUserId(user.id)
            .then (permissionsHash) ->
              logger.debug "permissions loaded on session for user: #{user.username}"
              req.session.permissions = permissionsHash
      .then () ->
        next()
      .catch (err) ->
        logger.debug "error while setting session user on request"
        next(err)

  allowAll: () ->
    return (req, res, next) ->
      next()

  requireLogin: (options = {}) ->
    defaultOptions =
      redirectOnFail: false
    options = _.merge(defaultOptions, options)
    return (req, res, next) -> Promise.try () ->
      if not req.user
        if options.redirectOnFail
          return res.redirect("/login?#{querystring.stringify(next: req.originalUrl)}")
        else
          return res.status(401).send("Please login to access this URI.")
      return process.nextTick(next)

  checkLogin: () ->
    return (req, res, next) -> Promise.try () ->
      logger.debug "checking for already logged-in user"
      if not req.user then return next()
      logger.debug "existing session found for username: #{req.user.username}"
      return doLoginRedirect(req, res)

  doLogin: () ->
    return (req, res, next) -> Promise.try () ->
      logger.debug "attempting to do login for username: #{req.body.username}"
      if req.user
        logger.debug "existing session found for username: #{req.body.username}"
        return doLoginRedirect(req, res)
      userService.verifyPassword(req.body.username, req.body.password)
        .catch (err) ->
          logger.debug "failed authentication: #{err}"
          return false
        .then (user) ->
          if not user
            req.query.errmsg = "Username and/or password does not match our records."
            return res.redirect("/login?#{querystring.stringify(req.query)}")
          else
            logger.debug "user logged in: #{user.username}"
            req.session.userid = user.id
            logger.debug "trying to set permissions on session for user: #{user.username}"
            return permissionsService.getPermissionsForUserId(user.id)
              .then (permissionsHash) ->
                logger.debug "permissions loaded on session for user: #{user.username}"
                req.session.permissions = permissionsHash
                return doLoginRedirect(req, res)
        .catch (err) ->
          logger.error "unexpected error during doLogin(): #{err}"
          next(err)
}
