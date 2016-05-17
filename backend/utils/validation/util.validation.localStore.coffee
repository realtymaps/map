_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
logger = require('../../config/logger').spawn('validation:localStore')
clsFactory = require '../util.cls'
clone =  require 'clone'

_errMsg = (thing) ->
  "no #{thing} provided, options are: #{JSON.stringify(thing)}"
# GOAL: To get a key from the continuation-local-storage and map it a object field
# example:
# options:
#   clsKey: 'req.user.id'
#   toKey: 'auth_user_id'
#
# Post transform:
#
# New Object:
#
# auth_user_id: SOME_ID
#
# Returns the mapped object.
module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    logger.debug "#{JSON.stringify options}"
    if !options?
      return Promise.reject new DataValidationError(_errMsg('options'), param, value)

    if !options?.clsKey
      return Promise.reject new DataValidationError(_errMsg('clsKey'), param, value)

    if !options?.toKey
      return Promise.reject new DataValidationError(_errMsg('toKey'), param, value)

    space = clsFactory().namespace

    firstRest = options.clsKey.firstRest('.')
    ret = clone(value) or {}
    maybeRet = space.get firstRest.first

    if options?.doLog
      logger.debug "first: '#{firstRest.first}'"
      logger.debug space, true

    unless maybeRet?
      logger.warn "first: '#{firstRest.first}'"
      logger.warn "maybeRet: is undefined"
      logger.warn space, true

    ret[options.toKey] = if firstRest.rest? then _.get(maybeRet, firstRest.rest) else maybeRet
    logger.debug ret, true
    ret
