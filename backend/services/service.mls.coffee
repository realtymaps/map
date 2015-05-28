logger = require '../config/logger'
retsHelper = require '../utils/util.retsHelpers'

module.exports =
  # Fetch a list of available MLS databases
  getDatabaseList: (postData) ->
    logger.info 'service.mls.getDatabaseList', postData
    retsHelper.getDatabaseList postData

  # Fetch a list of tables from a particular MLS database
  getTableList: (postData) ->
    logger.info 'service.mls.getTableList', postData
    retsHelper.getTableList postData, postData.databaseName