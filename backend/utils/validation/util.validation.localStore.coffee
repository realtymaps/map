_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
logger  = require '../../config/logger'
{getNamespace} = require 'continuation-local-storage'
{NAMESPACE} = require '../../config/config'

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
  # logger.debug "localStore: #{JSON.stringify options}"
  (param, value) -> Promise.try () ->
    if !options?
      return Promise.reject new DataValidationError("no options provided, options are: #{JSON.stringify(options)}", param, value)

    if !options?.clsKey
      return Promise.reject new DataValidationError("no clsKey provided, clsKey are: #{JSON.stringify(options)}", param, value)

    if !options?.toKey
      return Promise.reject new DataValidationError("no clsKey provided, clsKey are: #{JSON.stringify(options)}", param, value)

    space = getNamespace NAMESPACE
    firstRest = options.clsKey.firstRest('.')
    ret = {}
    # logger.debug "SPACE"
    # logger.debug space, true
    # logger.debug "first: #{firstRest.first}"
    maybeRet = space.get firstRest.first
    # logger.debug maybeRet
    ret[options.toKey] = if firstRest.rest? then _.get(maybeRet, firstRest.rest) else maybeRet
    ret
