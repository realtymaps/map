retsHelper = require '../utils/util.retsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'

module.exports =
  getDatabaseList: (req, res, next) ->
    logger.info 'mls.getDatabaseList', req.body
    retsHelper.getDatabaseList req.body
    .then (dbList) ->
      next new ExpressResponse(dbList)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  getTableList: (req, res, next) ->
    logger.info 'mls.getTableList', req.body
    retsHelper.getTableList req.body, req.body.databaseName
    .then (tableList) ->
      next new ExpressResponse(tableList)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500

  getColumnList: (req, res, next) ->
    logger.info 'mls.getColumnList', req.body
    retsHelper.getColumnList req.body, req.body.databaseName, req.body.tableName
    .then (columnList) ->
      next new ExpressResponse(columnList)
    .catch (error) ->
      next new ExpressResponse
        alert:
          msg: error.message
        500
