Promise = require "bluebird"
bcrypt = require 'bcrypt'

logger = require '../config/logger'
User = require("../models/model.user")
environmentSettingsService = require("../services/service.environmentSettings")


getUser = (attributes) ->
  return User.forge(attributes).fetch().then (user) -> return user.toJSON()

updateUser = (attributes) ->
  return User(attributes).save(patch: true).then (user) -> return user.toJSON()

# this skeleton for handling password hashes will make it easier to migrate
# hashes to a new algo if we ever need to
preprocessHash = (password) -> return new Promise (resolve, reject) ->
  if password.indexOf("bcrypt$") is 0
    hashData = algo: 'bcrypt', hash: password.slice("bcrypt$".length)
    hashData.needsUpdate = bcrypt.getRounds(hashData.hash) isnt environmentSettingsService["password hashing cost factor"]
    return resolve(hashData)
  # ... check for other valid formats and do preprocessing on them
  # ...
  # if nothing worked, indicate failure
  return reject(Promise.reject("failed to determine password hash algorithm"))

createPasswordHash = (password) ->
  return bcrypt.hashAsync(password, environmentSettingsService["password hashing cost factor"])
    .then (hash) -> return "bcrypt$#{hash}"


verifyPassword = (username, password) ->
  logger.debug "attempting to verify password for username: #{username}"
  return getUser({ username: username }).then (user) ->
    if not user
      # best practice is to go ahead and hash the password before returning,
      # to prevent timing attacks from determining validity of usernames
      return createPasswordHash(password).then (hash) -> return false
    promise = preprocessHash(user.password)
    promise.catch (error) ->
      logger.error "error while preprocessing password hash for username #{username}: #{error}"
    hashData = null
    return promise
      .then (data) ->
        hashData = data
        logger.debug "detected #{hashData.algo} password hash for username #{username}"
        switch hashData.algo
          when "bcrypt"
            return bcrypt.compareAsync(hashData.hash, password)
      .then (match) ->
        if not match
          return Promise.reject("given password doesn't match hash for username: #{username}")
        if hashData.needsUpdate
          # in the background, update this user's hash
          createPasswordHash(password)
            .then (hash) -> return updateUser(id: user.id, password: hash)
            .catch (err) -> logger.error "failed to update password hash for userid #{user.id}: #{err}"
        return Promise.resolve(user)
        

module.exports = {
  getUser: getUser
  updateUser: updateUser
  verifyPassword: verifyPassword
}
