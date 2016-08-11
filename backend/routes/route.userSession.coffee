Promise = require 'bluebird'
logger = require('../config/logger').spawn('route.userSession')
httpStatus = require '../../common/utils/httpStatus'
sessionSecurityService = require '../services/service.sessionSecurity'
userSessionService = require '../services/service.userSession'
profileService = require '../services/service.profiles'
userSvc = require('../services/services.user').user
projectSvc = require('../services/services.user').project
subscriptionSvc = require '../services/service.user_subscription.coffee'
userUtils = require '../utils/util.user'
ExpressResponse = require '../utils/util.expressResponse'
alertIds = require '../../common/utils/enums/util.enums.alertIds'
{methodExec} = require '../utils/util.route.helpers'
_ = require 'lodash'
auth = require '../utils/util.auth.coffee'

validation = require '../utils/util.validation'
safeColumns = (require '../utils/util.sql.helpers').columns
tables = require '../config/tables'
transforms = require '../utils/transforms/transforms.userSession'
internals = require './route.userSession.internals'
userInternals = require './route.user.internals'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'


# handle login authentication, and do all the things needed for a new login session
login = (req, res, next) -> Promise.try () ->
  if req.user
    # someone is logging in over an existing session...  shouldn't normally happen, but we'll deal
    logger.debug "attempting to log user out (someone is logging in): #{req.user.email}"
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.user = null
      logger.debug "attempting session regenerateAsync"
      req.session.regenerateAsync()
      logger.debug "post session regenerateAsync"
  else
    promise = Promise.resolve()

  promise.then () ->
    if !req.body.password
      logger.debug "no password specified for login: #{req.body.email}"
      return false
    logger.debug "attempting to do login for email: #{req.body.email}"
    userSessionService.verifyPassword(req.body.email, req.body.password)
  .catch (err) ->
    logger.debug "failed authentication: #{err}"
    return false
  .then (user) -> Promise.try ->
    userSessionService.verifyValidAccount(user)
  .then (user) ->
    if !user
      logger.debug "user undefined"
      return next new ExpressResponse(alert: {
        msg: 'Email and/or password does not match our records.'
        id: alertIds.loginFailure
      }, httpStatus.UNAUTHORIZED)
    else
      subscriptionSvc.getStatus user
      .then (subscription_status) ->
        req.user = user
        req.session.userid = user.id
        req.session.subscription = subscription_status
        userUtils.cacheUserValues(req)
        .then () ->
          req.session.saveAsync()
        .then () ->
          sessionSecurityService.ensureSessionCount(req)
        .then () ->
          sessionSecurityService.createNewSeries(req, res, !!req.body.remember_me)
        .then () ->
          internals.getIdentity(req, res, next)

setCurrentProfile = (req, res, next) -> Promise.try () ->
  unless req.body.currentProfileId
    next new ExpressResponse(alert: { msg: 'currentProfileId undefined'}, {status: httpStatus.BAD_REQUEST})

  req.session.current_profile_id = req.body.currentProfileId
  logger.debug "set req.session.current_profile_id: #{req.session.current_profile_id}"
  internals.updateCache(req, res, next)

updateState = (req, res, next) ->
  profileService.updateCurrent(req.session, req.body)
  .then () ->
    res.send()
  .catch (err) ->
    logger.error "error updating user state via API: #{err}"
    next(err)

profiles = (req, res, next) ->
  methodExec req,
    GET: () ->
      # if user is subscriber, use service endpoint that includes sandbox creation and display
      if userUtils.isSubscriber(req)
        promise = profileService.getProfiles req.user.id

      # user is a client, and unallowed to deal with sandboxes
      else
        promise = profileService.getClientProfiles req.user.id

      promise.then (result) ->
        res.json result

    PUT: () ->
      validation.validateAndTransformRequest(req.body, transforms.profiles.PUT)
      .then (validBody) ->
        profileService.update(validBody, req.user.id)
        .then () ->
          logger.debug 'SESSION: clearing profiles'
          delete req.session.profiles#to force profiles refresh in cache
          internals.updateCache(req, res, next)

newProject = (req, res, next) ->

  throw new Error 'Error creating new project, name is required' unless req.body.name

  Promise.try () ->
    profileService.getCurrentSessionProfile req.session

  .then (profile) ->
    toSave = _.extend({auth_user_id: req.user.id, can_edit: true}, req.body)

    # If current profile is sandbox, convert it to a regular project
    if profile.sandbox is true
      toSave.sandbox = false
      projectSvc.update profile.project_id, toSave, safeColumns.project
      .then () ->
        profile # leave the current profile selected

    # Otherwise create a new profile
    else
      if req.body.copyCurrent is true
        _.extend toSave, _.pick(profile, ['filters', 'map_toggles', 'map_position', 'map_results'])

      profileService.create toSave

  .then (newProfile) ->
    req.session.current_profile_id = newProfile.id
    logger.debug "set req.session.current_profile_id: #{req.session.current_profile_id}"
    delete req.session.profiles # to force profiles refresh in cache
    internals.updateCache(req, res, next)


image = (req, res, next) ->
  methodExec req,
    GET: () -> userInternals.getImage {req, res, next, entity: req.user}
    PUT: () ->
      userInternals.updateImage {req, next, entity: req.user}
      .then ()->
        internals.updateCache(req, res, next)

companyImage = (req, res, next) ->
  methodExec req,
    GET: () ->
      userInternals.getCompanyImage(req, res, next)

    PUT: () -> Promise.try ->
      userInternals.updateCompanyImage {
        req
        next
        entity: _.omit(req.body, 'blob')
      }
      .then ()->
        internals.updateCache(req, res, next)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to PUT company image')



root = (req, res, next) ->
  methodExec req,
    PUT: () ->
      validation.validateAndTransformRequest(req.body, transforms.root.PUT())
      .then (validBody) ->
        userSvc.update(req.session.userid, validBody, internals.safeRootFields)
      .then () ->
        internals.updateCache(req, res, next)


#only way to add a company for a logged in user (otherwise use admin route /company)
companyRoot = (req, res, next) ->
  methodExec req,
    POST: () ->
      validation.validateAndTransformRequest(req.body, transforms.companyRoot.POST())
      .then (validBody) ->
        tables.user.company.transaction (transaction) ->

          q = if !req.user.company_id? and !validBody.id?
            tables.user.company({transaction}).insert(validBody).returning('id')
            .then ([id]) ->
              id
          else
            id = req.user.company_id || validBody.id
            tables.user.company({transaction})
            .update _.pick validBody, internals.safeRootCompanyFields
            .where {id}
            .then ->
              id

          q.then (company_id) ->
            if !company_id?
              throw new Error('Error creating new company')
            logger.debug company_id

            tables.auth.user({transaction})
            .where id: req.user.id
            .update {company_id}
            .then () ->
              internals.updateCache(req, res, next)

updatePassword = (req, res, next) ->
  validation.validateAndTransformRequest(req.body, transforms.updatePassword)
  .then (validBody) ->
    userSessionService.updatePassword(req.user, validBody.password)
    .then ->
      res.json(true)

module.exports =
  root:
    method: 'put'
    handle: root

  companyRoot:
    method: 'post'
    handle: companyRoot

  login:
    method: 'post'
    handle: login

  logout: auth.logout

  identity: internals.getIdentity

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
    handle: setCurrentProfile

  newProject:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: newProject

  image:
    methods: ['get', 'put']
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: image

  companyImage:
    methods: ['get', 'put']
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: companyImage

  updatePassword:
    method: 'put'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: updatePassword
