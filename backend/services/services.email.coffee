Promise = require 'bluebird'
randomstring = require 'randomstring'
userTable = require('../config/tables').auth.user
{expectSingleRow} = require '../utils/util.sql.helpers'
keystore = require "../services/service.keystore"
{MissingVarError, UpdateFailedError} = require '../utils/errors/util.errors.crud'
{ValidateEmailHashTimedOutError} = require '../utils/errors/util.errors.email'
moment = require 'moment'
emailThreshMilliSeconds = null

makeEmailHash = () ->
  randomstring.generate()

keystore.getValue('email_minutes', namespace: 'time_limits').then (val) ->
  emailThreshMilliSeconds = moment.duration(minutes:val).asMilliseconds()

_isValidWithinTime = (timestamp) ->
  !(Date.now() - timestamp >= emailThreshMilliSeconds)

_getUserByHash = (hash) ->
  userTable()
  .where(email_validation_hash: hash, email_is_valid: false)
  .then expectSingleRow

validateHash = (hash) -> Promise.try () ->
  unless emailThreshMilliSeconds
    throw new MissingVarError("emailThreshMilliSeconds is not defined")

  _getUserByHash(hash)
  .then (user) ->
    unless _isValidWithinTime(user.email_validation_hash_created_time)
      throw new ValidateEmailHashTimedOutError("Validaiton Hash has not been confirmed with the alotted time period.")
    user.email_is_valid = true
    user.email_validation_attempt += 1
    userTable()
    .where(id: user.id)
    .returning('email_is_valid')
    .update
      email_is_valid: user.email_is_valid
      email_validation_attempt: user.email_validation_attempt
      is_active: true
    .then ([returned]) ->
      unless returned == user.email_is_valid
        throw new UpdateFailedError("failed updating email_is_valid")
      true

cancelHash =
  create: (authUser) ->
    userTable()
    .where id: authUser.id
    .update cancel_email_hash: makeEmailHash()

  getUser: (authUser) ->
    userTable()
    .where id: authUser.id, cancel_email_hash: authUser.cancel_email_hash

module.exports =
  makeEmailHash: makeEmailHash
  cancelHash: cancelHash
  validateHash: validateHash
  emailPlatform: require('./email/vero')
