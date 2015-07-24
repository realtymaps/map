Promise = require 'bluebird'

logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
sessionSecurityService = require '../services/service.sessionSecurity'
userSessionService = require '../services/service.userSession'
userSvc = require('../services/services.user').user
userUtils = require '../utils/util.user'
ExpressResponse = require '../utils/util.expressResponse'
alertIds = require '../../common/utils/enums/util.enums.alertIds'
config = require '../config/config'
{methodExec} = require '../utils/util.route.helpers'
_ = require 'lodash'
auth = require '../utils/util.auth.coffee'
{NotFoundError} = require '../utils/util.route.helpers'
{parseBase64} = require '../utils/util.image'
sizeOf = require 'image-size'

dimensionLimits = config.IMAGES.dimensions.profile

logger.functions auth

safeUserFields = [
  'cell_phone'
  'email'
  'first_name'
  'id'
  'last_name'
  'username'
  'work_phone'
  'account_image_id'
  'address_1'
  'address_2'
  'us_state_id'
  'zip'
  'city'
  'website_url'
  'account_use_type_id'
  'company_id'
]

# handle login authentication, and do all the things needed for a new login session
login = (req, res, next) -> Promise.try () ->
  if req.user
    # someone is logging in over an existing session...  shouldn't normally happen, but we'll deal
    logger.debug "attempting to log user out (someone is logging in): #{req.user.username}"
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.user = null
      # logger.debug "attempting session regenerateAsync"
      req.session.regenerateAsync()
      # logger.debug "post session regenerateAsync"
  else
    promise = Promise.resolve()

  promise.then () ->
    if !req.body.password
      logger.debug "no password specified for login: #{req.body.username}"
      return false
    logger.debug "attempting to do login for username: #{req.body.username}"
    userSessionService.verifyPassword(req.body.username, req.body.password)
  .catch (err) ->
    logger.debug "failed authentication: #{err}"
    return false
  .then (user) ->
    if not user
      return next new ExpressResponse(alert: {
        msg: "Username and/or password does not match our records."
        id: alertIds.loginFailure
      }, httpStatus.UNAUTHORIZED)
    else
      req.user = user
      logger.debug "session: #{req.session}"
      req.session.userid = user.id

      userUtils.cacheUserValues(req)
      .then () ->
        req.session.saveAsync()
      .then () ->
        sessionSecurityService.ensureSessionCount(req)
      .then () ->
        sessionSecurityService.createNewSeries(req, res, !!req.body.remember_me)
      .then () ->
        identity(req, res, next)
  .catch (err) ->
    logger.error "unexpected error during login(): #{err}"
    next(err)

identity = (req, res, next) ->
  if req.user
    # here we should probaby return some things from the user's profile as well, such as name
    res.json
      identity:
        user: _.pick req.user, safeUserFields
        permissions: req.session.permissions
        groups: req.session.groups
        environment: config.ENV
        profiles: req.session.profiles
        currentProfileId: req.session.current_profile_id
  else
    res.json
      identity: null

updateCache = (req, res, next) ->
  userUtils.cacheUserValues(req)
  .then () ->
    req.session.saveAsync()
  .then () ->
    identity(req, res, next)

currentProfile = (req, res, next) -> Promise.try () ->
  unless req.body.currentProfileId
    next new ExpressResponse(alert: { msg: "currentProfileId undefined"}, httpStatus.BAD_REQUEST)

  req.session.current_profile_id = req.body.currentProfileId
  logger.debug "set req.session.current_profile_id: #{req.session.current_profile_id}"
  updateCache(req, res, next)

updateState = (req, res, next) ->
  userSessionService.updateCurrentProfile(req.session, req.body)
  .then () ->
    res.send()
  .catch (err) ->
    logger.error "error updating user state via API: #{err}"
    next(err)

profiles = (req, res, next) ->
  auth_user_id = req.session.userid
  methodExec req,
    GET: () ->
      userSessionService.getProfiles(auth_user_id)

    PUT: () ->
      q = userSessionService.updateProfile(req.body)
      q.then ()->
        delete req.session.profiles#to force profiles refresh in cache
        updateCache(req, res, next)
  .then (result) ->
    res.json result
  .catch (err) ->
    logger.error err

image = (req, res, next) ->
  methodExec req,
    GET: () -> Promise.try ->
      userSessionService.getImage(req.user)
      .then (result) ->
        unless result?.blob?
          return next new ExpressResponse({} , httpStatus.NOT_FOUND)

        parsed = parseBase64(result.blob)
        res.setHeader("Content-Type", parsed.type)
        buf = new Buffer(parsed.data, 'base64')
        dim = sizeOf buf
        if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
          logger.error "Dimensions of #{JSON.stringify dim} are outside of limits for user.id: #{req.user.id}"
        res.send(buf)

    PUT: () -> Promise.try ->
      # logger.debug req.body.blob
      if !req.body?.blob.contains "image/" or !req.body?.blob.contains "base64"
        return next new ExpressResponse({alert: "image has incorrect formatting."} , httpStatus.BAD_REQUEST)

      if !req.body?
        return next new ExpressResponse({alert: "undefined image blob"} , httpStatus.BAD_REQUEST)

      parsed = parseBase64(req.body.blob)
      buf = new Buffer(parsed.data, 'base64')
      dim = sizeOf buf

      if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
        return next new ExpressResponse({alert: "Dimensions of #{JSON.stringify dim} are outside of limits for user.id: #{req.user.id}"} , httpStatus.BAD_REQUEST)

      userSessionService.upsertImage(req.user, req.body.blob)
      .then ()->
        updateCache(req, res, next)

#main entry point to update root user info
_safeRootFields = safeUserFields.concat([])

['company_id'].forEach ->
  _safeRootFields.pop()

root = (req, res, next) ->
  methodExec req,
    PUT: () ->
      result = null
      # logger.debug req.body
      userSvc.update(req.session.userid, req.body, _safeRootFields)
      .then () ->
        updateCache(req, res, next)

module.exports =
  root:
    method: 'put'
    handle: root

  login:
    method: 'post'
    handle: login

  logout: auth.logout

  identity: identity

  updateState:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: updateState

  profiles:
    methods: ['get', 'put']
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: profiles

  currentProfile:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: currentProfile

  image:
    methods: ['get', 'put']
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: image
