Promise = require 'bluebird'

logger = require('../config/logger').spawn('route.userSession')
httpStatus = require '../../common/utils/httpStatus'
sessionSecurityService = require '../services/service.sessionSecurity'
userSessionService = require '../services/service.userSession'
profileService = require '../services/service.profiles'
userSvc = require('../services/services.user').user
companySvc = require('../services/services.user').company
projectSvc = require('../services/services.user').project
subscriptionSvc = require '../services/service.user_subscription.coffee'
userUtils = require '../utils/util.user'
ExpressResponse = require '../utils/util.expressResponse'
alertIds = require '../../common/utils/enums/util.enums.alertIds'
config = require '../config/config'
{methodExec} = require '../utils/util.route.helpers'
_ = require 'lodash'
auth = require '../utils/util.auth.coffee'
{parseBase64} = require '../utils/util.image'
sizeOf = require 'image-size'
validation = require '../utils/util.validation'
{validators} = validation
safeColumns = (require '../utils/util.sql.helpers').columns
emailTransforms = require('../utils/transforms/transforms.email')
{InValidEmailError, InActiveUserError} = require '../utils/errors/util.errors.args'
tables = require '../config/tables'
moment = require 'moment'

dimensionLimits = config.IMAGES.dimensions.profile


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
  'parent_id'
]

# handle login authentication, and do all the things needed for a new login session
login = (req, res, next) -> Promise.try () ->
  if req.user
    # someone is logging in over an existing session...  shouldn't normally happen, but we'll deal
    logger.debug "attempting to log user out (someone is logging in): #{req.user.email}"
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
    if not user
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
          identity(req, res, next)

identity = (req, res, next) ->
  res.json identity: userSessionService.getIdentity req

updateCache = (req, res, next) ->
  userUtils.cacheUserValues(req)
  .then () ->
    req.session.saveAsync()
  .then () ->
    identity(req, res, next)

currentProfile = (req, res, next) -> Promise.try () ->
  unless req.body.currentProfileId
    next new ExpressResponse(alert: { msg: 'currentProfileId undefined'}, httpStatus.BAD_REQUEST)

  req.session.current_profile_id = req.body.currentProfileId
  logger.debug "set req.session.current_profile_id: #{req.session.current_profile_id}"
  profile = req.session.profiles[req.session.current_profile_id]
  profile.rm_modified_time = moment()
  # Note it doesn't really matter what value rm_modified_time is set to since it gets updated via trigger anyway
  tables.user.profile().update(rm_modified_time: profile.rm_modified_time).where('id', profile.id)
  .then ->
    updateCache(req, res, next)

updateState = (req, res, next) ->
  userSessionService.updateCurrentProfile(req.session, req.body)
  .then () ->
    res.send()
  .catch (err) ->
    logger.error "error updating user state via API: #{err}"
    next(err)

profiles = (req, res, next) ->
  methodExec req,
    GET: () ->
      userSessionService.getProfiles req.user.id
      .then (result) ->
        res.json result
    PUT: () ->
      transforms =
        account_image_id: validators.integer()
        filters: validators.object()
        favorites: validators.object()
        map_toggles: validators.object()
        map_position: validators.object()
        map_results: validators.object()
        auth_user_id: validators.integer()
        parent_auth_user_id: validators.integer()
        properties_selected: validators.object()
        id:
          transforms: [validators.integer()]
          required: true

      validation.validateAndTransformRequest(req.body, transforms)
      .then (validBody) ->
        q = userSessionService.updateProfile(validBody, req.user.id)
        q.then ()->
          logger.debug 'SESSION: clearing profiles'
          delete req.session.profiles#to force profiles refresh in cache
          updateCache(req, res, next)

newProject = (req, res, next) ->

  throw new Error 'Error creating new project, name is required' unless req.body.name

  Promise.try () ->
    profileService.getCurrentSessionProfile req.session

  .then (profile) ->
    toSave = _.extend auth_user_id: req.user.id, req.body

    # If current profile is sandbox, convert it to a regular project
    if profile.sandbox is true
      toSave.sandbox = false
      projectSvc.update profile.project_id, toSave, safeColumns.project
      .then () ->
        profile # leave the current profile selected

    # Otherwise create a new profile
    else
      if req.body.copyCurrent is true
        _.extend toSave, _.pick(profile, ['filters', 'map_toggles', 'map_position', 'map_results', 'properties_selected'])

      profileService.create toSave

  .then (newProfile) ->
    req.session.current_profile_id = newProfile.id
    logger.debug "set req.session.current_profile_id: #{req.session.current_profile_id}"
    delete req.session.profiles # to force profiles refresh in cache
    updateCache(req, res, next)

getImage = (req, res, next, entity, typeStr = 'user') -> Promise.try ->
  userSessionService.getImage(entity)
  .then (result) ->
    unless result?.blob?
      return next new ExpressResponse({} , httpStatus.NOT_FOUND)

    parsed = parseBase64(result.blob)
    res.setHeader('Content-Type', parsed.type)
    buf = new Buffer(parsed.data, 'base64')
    dim = sizeOf buf
    if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
      logger.error "Dimensions of #{JSON.stringify dim} are outside of limits for entity.id: #{entity.id}; type: #{typeStr}"
    res.send(buf)

updateImage = (req, res, next, entity, typeStr = 'user', upsertImageFn = userSessionService.upsertImage) -> Promise.try ->
  # logger.debug req.body.blob
  if !req.body?.blob.contains 'image/' or !req.body?.blob.contains 'base64'
    return next new ExpressResponse({alert: 'image has incorrect formatting.'} , httpStatus.BAD_REQUEST)

  if !req.body?
    return next new ExpressResponse({alert: 'undefined image blob'} , httpStatus.BAD_REQUEST)

  parsed = parseBase64(req.body.blob)
  buf = new Buffer(parsed.data, 'base64')
  dim = sizeOf buf

  if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
    return next new ExpressResponse({alert: "Dimensions of #{JSON.stringify dim} are outside of limits for user.id: #{req.user.id}"} , httpStatus.BAD_REQUEST)

  upsertImageFn(entity, req.body.blob)
  .then ()->
    updateCache(req, res, next)

image = (req, res, next) ->
  methodExec req,
    GET: () -> getImage(req, res, next, req.user)
    PUT: () -> updateImage(req, res, next, req.user)

companyImage = (req, res, next) ->
  methodExec req,
    GET: () ->
      transforms =
        account_image_id:
          required: true

      validation.validateAndTransformRequest(req.params, transforms)
      .then (validParams) ->
        getImage(req, res, next, {account_image_id: validParams.account_image_id}, 'company')

    PUT: () ->
      updateImage(req, res, next, _.omit(req.body, 'blob'), 'company', userSessionService.upsertCompanyImage)


#main entry point to update root user info
_safeRootFields = safeUserFields.concat([])

['company_id'].forEach ->
  _safeRootFields.pop()

root = (req, res, next) ->
  methodExec req,
    PUT: () ->
      transforms =
        first_name: validators.string(minLength: 2)
        last_name: validators.string(minLength: 2)
        address_1: validators.string(regex: config.VALIDATION.address)
        city: validators.string(minLength: 2)
        us_state_id: required:true
        zip: required:true
        cell_phone:
          transform: [
            validators.string(regex: config.VALIDATION.phone)
          ]
          required: true
        work_phone: validators.string(regex: config.VALIDATION.phone)
        username:
          transform: [
            validators.string(minLength: 3)
          ]
          required: true
        website_url: validators.string(regex: config.VALIDATION.url)
        email: emailTransforms.email(req.user.id)

      validation.validateAndTransformRequest(req.body, transforms)
      .then (validBody) ->
        userSvc.update(req.session.userid, validBody, _safeRootFields)
        .then () ->
          updateCache(req, res, next)

_safeRootCompanyFields = [
  'address_1'
  'address_2'
  'zip'
  'name'
  'us_state_id'
  'phone'
  'fax'
  'website_url'
]

#only way to add a company for a logged in user (otherwise use admin route /company)
companyRoot = (req, res, next) ->
  methodExec req,
    POST: () ->
      if !req.user.company_id? and !req.body.id?
        q = companySvc.create(req.body).returning('id')
      else
        id = req.user.company_id || req.body.id
        q = companySvc.update(id, req.body, _safeRootCompanyFields)
        .then ->
          id
      q.then (id) ->
        unless id?
          throw new Error('Error creating new company')
        logger.debug id
        req.user.company_id = id
        userSvc.update(req.user.id, req.user).then ->
          updateCache(req, res, next)

updatePassword = (req, res, next) ->
  transforms =
    password: validators.string(regex: config.VALIDATION.password)

  validation.validateAndTransformRequest(req.body, transforms)
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
