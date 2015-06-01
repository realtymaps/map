retsHelper = require '../utils/util.retsHelpers'
ExpressResponse = require '../utils/util.expressResponse'

module.exports =
  getDatabaseList: (req, res, next) ->
    logger.info 'mls.getDatabaseList', postData
    retsHelper.getDatabaseList req.body
    .then (dbList) ->
      res.send dbList
    .catch (error) ->
      res.send new ExpressResponse
        alert:
          msg: error.message
        500

  getTableList: (req, res, next) ->
    logger.info 'mls.getTableList', postData
    retsHelper.getTableName req.body, req.body.databaseName
    .then (tableList) ->
      res.send tableList
    .catch (error) ->
      res.send new ExpressResponse
        alert:
          msg: error.message
        500

  getColumnList: (req, res, next) ->
    logger.info 'mls.getColumnList', postData
    retsHelper.getColumnList req.body, req.body.databaseName, req.body.tableName
    .then (columnList) ->
        res.send columnList
    .catch (error) ->
      res.send new ExpressResponse
        alert:
          msg: error.message
        500
