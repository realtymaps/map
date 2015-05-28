_ = require 'lodash'
retsHelper = require '../utils/util.retsHelpers'
logger = require '../config/logger'

# Fetch a list of available MLS databases
getDatabaseList = (req, res, next) ->
  mlsInfo = req.body
  logger.info mlsInfo
  retsHelper.getDatabaseList(mlsInfo)

module.exports =
  getDatabaseList: getDatabaseList
