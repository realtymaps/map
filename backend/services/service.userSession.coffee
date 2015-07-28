Promise = require "bluebird"
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
User = require "../models/model.user"
{userData} = require "../config/tables"
environmentSettingsService = require "../services/service.environmentSettings"
{singleRow} = require '../utils/util.sql.helpers'
profileSvc = require './service.profiles'
accountImagesSvc = require('./services.user').account_images
{NotFoundError} =  require '../utils/util.route.helpers'

getUser = (attributes) ->
  User.forge(attributes)
  .fetch()
  .then (user) ->
    if not user
      return {}
    else
      return user.toJSON()

updateUser = (attributes) ->
  User.forge(attributes)
  .save(attributes, patch: true)
  .then (user) ->
    if not user
      return {}
    else
      return user.toJSON()

# this skeleton for handling password hashes will make it easier to migrate
# hashes to a new algo if we ever need to
preprocessHash = (password) ->
  Promise.try () ->
    hashData = {}
    if password?.indexOf("bcrypt$") == 0
      hashData.algo = 'bcrypt'
      hashData.hash = password.slice("bcrypt$".length)
      return environmentSettingsService.getSettings()
      .then (settings) ->
        hashData.needsUpdate = bcrypt.getRounds(hashData.hash) isnt settings["password hashing cost factor"]
        return hashData
    # ... else check for other valid formats and do preprocessing for them
    # ...
    # if nothing worked, indicate failure
    return Promise.reject("failed to determine password hash algorithm")

createPasswordHash = (password) ->
  environmentSettingsService.getSettings()
  .then (settings) ->
    cost = settings["password hashing cost factor"]
    #logger.debug "creating bcrypt password hash with 2^#{cost} rounds"
    return bcrypt.hashAsync(password, cost)
  .then (hash) -> return "bcrypt$#{hash}"


verifyPassword = (username, password) ->
  #logger.debug "attempting to verify password for username: #{username}"
  getUser({ username: username })
  .then (user) ->
    if not user or not user?.password
      # best practice is to go ahead and hash the password before returning,
      # to prevent timing attacks from determining validity of usernames
      return createPasswordHash(password).then (hash) -> return false
    hashData = null
    preprocessHash(user.password)
    .catch (err) ->
      logger.error "error while preprocessing password hash for username #{username}: #{err}"
      Promise.reject(err)
    .then (data) ->
      hashData = data
      #logger.debug "detected #{hashData.algo} password hash for username: #{username}"
      switch hashData.algo
        when "bcrypt"
          return bcrypt.compareAsync(password, hashData.hash)
    .then (match) ->
      if not match
        return Promise.reject("given password doesn't match hash for username: #{username}")
      #logger.debug "password verified for username: #{username}"
      if hashData.needsUpdate
        # in the background, update this user's hash
        logger.info "updating password hash for username: #{username}"
        createPasswordHash(password)
        .then (hash) -> return updateUser(id: user.id, password: hash)
        .catch (err) -> logger.error "failed to update password hash for userid #{user.id}: #{err}"
      return user

###
map_position -  is to hold center, zoom, bounds.., altitude.. any kind of position relative map info
map_results =
  selectedResult: {}
  results: [] #maybe
NOTE: IF columns for auth_user_profile need to be deleted Session.state should be purged! Otherwise,
  a invalid bookshelf object of old state will be queried.
###
_userStateCols = ['map_position', 'map_toggles', 'map_results']
#TODO: THIS NEEDS TO BE RETHOUGHT this special handling of removing types is very difficult
# to remember and causes significant debugging
_filtersToRemove = _userStateCols.concat(['bounds','returnType'])

_commonCaptureState = (req, stateUpdate = {}) ->
  hasSomeState = false
  _userStateCols.forEach (col) ->
    stateUpdate[col] = req.query[col] if req.query[col]?
    hasSomeState = true if stateUpdate[col]?

  if hasSomeState
    profileSvc.updateCurrent(req.session, stateUpdate)
  else
    Promise.resolve({})

captureMapState = (req, res, next) -> Promise.try () ->
  _commonCaptureState(req)
  .then () ->
    next()

captureMapFilterState = (req, res, next) -> Promise.try () ->
  filters = _.clone(req.query)
  _filtersToRemove.forEach (removeParam) ->
    delete filters[removeParam]
  _commonCaptureState(req, filters: filters)
  .then () ->
    next()

getImage = (entity) ->
  return Promise.resolve(null) unless entity?.account_image_id?
  singleRow accountImagesSvc.getById(entity.account_image_id)

upsertImage = (entity, blob, tableFn = userData.user) ->
  getImage(entity)
  .then (image) ->
    if image
      #update
      logger.debug "updating image for account_image_id: #{entity.account_image_id}"
      return accountImagesSvc.update(entity.account_image_id, blob:blob)
    #create
    logger.debug "creating image"
    singleRow accountImagesSvc.create(blob:blob).returning("id")
    .then (id) ->
      logger.debug "saving account_image_id: #{id}"
      tableFn().update(account_image_id: id)
      .where(id:entity.id)

upsertCompanyImage = (entity, blob) ->
  upsertImage(entity,blob, userData.company)

updateUserNamePassword = (user, newUserName, password) ->
  singleRow userData.user().where(username: newUserName).whereNot(id:user.id).count()
  .then (row) ->
    if row.count > 0
      return Promise.reject "Username already exists"
    createPasswordHash(password).then (password) ->
      userData.user().update(username: newUserName, password:password)
      .where(id: user.id)

module.exports =
  getUser: getUser
  updateUser: updateUser
  verifyPassword: verifyPassword
  getProfile: profileSvc.getFirst
  updateCurrentProfile: profileSvc.updateCurrent
  updateProfile: profileSvc.update
  captureMapState: captureMapState
  captureMapFilterState: captureMapFilterState
  getProfiles: profileSvc.getProfiles
  getImage: getImage
  upsertImage: upsertImage
  upsertCompanyImage: upsertCompanyImage
  updateUserNamePassword: updateUserNamePassword
