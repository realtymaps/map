Promise = require 'bluebird'
userServices = require '../services/services.user'
{expectSingleRow} = require '../utils/util.sql.helpers'
keystore = require "../services/service.keystore"
{MissingVarError, UpdateFailedError} = require '../utils/errors/util.error.crud'
moment = require 'moment'
userService = userServices.user
emailThreshMilliSeconds = null

keystore.getValue('email_minutes', namespace: 'time_limits').then (val) ->
  emailThreshMilliSeconds = moment.duration(minutes:val).asMilliseconds()

isValidWithinTime = (timestamp) ->
  !(Date.now() - timestamp >= emailThreshMilliSeconds)

getUserByHash = (hash) ->
  userServices.dbFn().where(email_validation_hash: hash)
  .then expectSingleRow

validateHash = (hash) -> Promise.try () ->
  unless emailThreshMilliSeconds
    throw new MissingVarError("emailThreshMilliSeconds is not defined")

  getUserByHash(hash)
  .then (user) ->
    return true if user.email_is_valid
    return false unless isValidWithinTime(user.email_validation_hash_created_time)
    user.email_is_valid = true
    user.email_validation_attempt += 1
    userService.dbFn()
    .where(id: user.id)
    .returning('email_is_valid')
    .update(email_is_valid: user.email_is_valid, email_validation_attempt: user.email_validation_attempt)
    .then (returned) ->
      unless returned == user.email_is_valid
        throw new UpdateFailedError("failed updating email_is_valid")
      true


module.exports = validateHash
