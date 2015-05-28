mlsService = require '../services/service.mls'

module.exports =
  getDatabaseList: (req, res, next) ->
    mlsService.getDatabaseList req.body
    .then (dbList) ->
        res.send dbList

  getTableList: (req, res, next) ->
    mlsService.getTableList req.body
    .then (tableList) ->
        res.send tableList
