mlsService = require '../services/service.mls'
ExpressResponse = require '../utils/util.expressResponse'

module.exports =
  getDatabaseList: (req, res, next) ->
    mlsService.getDatabaseList req.body
    .then (dbList) ->
      res.send dbList
    .catch (error) ->
      res.send new ExpressResponse
        alert:
          msg: error.message
        500

  getTableList: (req, res, next) ->
    mlsService.getTableList req.body
    .then (tableList) ->
      res.send tableList
    .catch (error) ->
      res.send new ExpressResponse
        alert:
          msg: error.message
        500

  getColumnList: (req, res, next) ->
    mlsService.getColumnList req.body
    .then (columnList) ->
        res.send columnList
    .catch (error) ->
      res.send new ExpressResponse
        alert:
          msg: error.message
        500
