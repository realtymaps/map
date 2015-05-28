logger = require '../config/logger'
retsHelper = require '../utils/util.retsHelpers'

module.exports =
  # Fetch a list of available MLS databases
  getDatabaseList: (serverInfo) ->
    logger.info 'service.mls.getDatabaseList', serverInfo
    retsHelper.getDatabaseList serverInfo
