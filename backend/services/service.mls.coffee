Promise = require "bluebird"
_ = require 'lodash'

# Fetch a list of available MLS databases
_getDatabaseList = (mlsInfo) ->
  retsClient = new rets.Client mlsInfo

  retsClient.login()
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "login to RETS server failed")
  .then () ->
    retsClient.metadata.getResources()
  .finally () ->
    retsClient.logout()

getDatabaseList = (req, res, next) -> Promise.try () ->
  _getDatabaseList(req)
  .then () ->
    next()

module.exports =
  getDatabaseList: getDatabaseList
