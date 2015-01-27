Promise = require "bluebird"
bcrypt = require 'bcrypt'

logger = require '../config/logger'
User = require("../models/model.user")
UserState = require("../models/model.userState")
environmentSettingsService = require("../services/service.environmentSettings")
StringToBoolean = require '../../common/utils/util.stringToBoolean'


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

getUserState = (userId) ->
  UserState.forge(id: userId)
  .fetch()
  .then (userState) ->
    if not userState
      UserState.forge({id: userId})
      .save({id: userId}, {method: 'insert'})
      .then () ->
        return {}
    else
      result = userState.toJSON()
      delete result.id
      return result

updateUserState = (session, partialState) -> Promise.try () ->
  # need the id for lookup, so we don't want to allow it to be set this way
  delete partialState.id
  
  #avoid unnecessary saves as there is the possibility for race conditions
  needsSave = false
  for key,part of partialState
    if !_.isEqual part, session.state[key]
      needsSave = true
      break
  if needsSave
    _.extend(session.state, partialState)
    session.saveAsync()  # save immediately to prevent problems from overlapping AJAX calls
  
  # now save to the global state
  UserState.forge(id: session.userid)
  .save(session.state, {method: 'update'})
  .then (userState) ->
    if not userState
      return {}
    else
      result = userState.toJSON()
      delete result.id
      return result

captureMapState = (req, res, next) -> Promise.try () ->
  stateUpdate = {}
  if req.query.center?
    stateUpdate.map_center = req.query.center
  if req.query.zoom?
    stateUpdate.map_zoom = req.query.zoom
  if req.query.toggles?
    stateUpdate.map_toggles = req.query.toggles
  updateUserState(req.session, stateUpdate)
  .then () ->
    next()

captureMapFilterState = (req, res, next) -> Promise.try () ->
  filters = _.clone(req.query)
  _.forEach ['center', 'zoom', 'bounds', 'toggles'], (removeParam) ->
    delete filters[removeParam]

  stateUpdate = {filters: filters}
  if req.query.center?
    stateUpdate.map_center = req.query.center
  if req.query.zoom?
    stateUpdate.map_zoom = req.query.zoom
  if req.query.toggles?
    stateUpdate.map_toggles = req.query.toggles
  updateUserState(req.session, stateUpdate)
  .then () ->
    next()

module.exports = {
  getUser: getUser
  updateUser: updateUser
  verifyPassword: verifyPassword
  getUserState: getUserState
  updateUserState: updateUserState
  captureMapState: captureMapState
  captureMapFilterState: captureMapFilterState
}
