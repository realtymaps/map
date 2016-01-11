Promise = require 'bluebird'
userServices = require '../services/services.user'
{expectSingleRow} = require '../utils/util.sql.helpers'
keystore = require "../services/service.keystore"
{MissingVarError, UpdateFailedError} = require '../utils/errors/util.error.crud'
moment = require 'moment'
userService = userServices.user
emailThreshMilliSeconds = null
vero = require 'vero-promise'

keystore.getValue('email_minutes', namespace: 'time_limits').then (val) ->
  emailThreshMilliSeconds = moment.duration(minutes:val).asMilliseconds()

_isValidWithinTime = (timestamp) ->
  !(Date.now() - timestamp >= emailThreshMilliSeconds)

_getUserByHash = (hash) ->
  userServices.dbFn().where(email_validation_hash: hash)
  .then expectSingleRow

validateHash = (hash) -> Promise.try () ->
  unless emailThreshMilliSeconds
    throw new MissingVarError("emailThreshMilliSeconds is not defined")

  _getUserByHash(hash)
  .then (user) ->
    return true if user.email_is_valid
    return false unless _isValidWithinTime(user.email_validation_hash_created_time)
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

emailPlatform = do ->
  # * `subscriptionStatus`  identify a user as 'paid or default or more' {[string]}.
  #
  # Returns the vero-promise response as Promise([user, event]).
  signUp = (user, verifyUrl, subscriptionStatus) ->
    vero.createUserAndTrackEvent(
      userDBId, user.email, _.extend(
        _.pick(user, [
          'first_name'
          'last_name'
          'plan'
          ]),
        subscription_status: subscriptionStatus)
    , 'New user email', { verify_url: verifyUrl })

module.exports =
  validateHash: validateHash
  emailPlatform: emailPlatform
