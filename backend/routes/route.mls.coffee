retsHelper = require '../utils/util.mlsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
mlsConfigService = require '../services/service.mls_config'

module.exports =
  getDatabaseList: (req, res, next) ->
    mlsConfigService.getById(req.params.mlsId)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
          404
      else
        retsHelper.getDatabaseList mlsConfig
        .then (list) ->
          next new ExpressResponse(list)
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500

  getTableList: (req, res, next) ->
    mlsConfigService.getById(req.params.mlsId)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
          404
      else
        retsHelper.getTableList mlsConfig, req.params.databaseId
        .then (list) ->
          next new ExpressResponse(list)
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500

  getColumnList: (req, res, next) ->
    mlsConfigService.getById(req.params.mlsId)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
          404
      else
        retsHelper.getColumnList mlsConfig, req.params.databaseId, req.params.tableId
        .then (list) ->
          next new ExpressResponse(list)
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500

  getDataDump: (req, res, next) ->
    mlsConfigService.getById(req.params.mlsId)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
          404
      else
        limit = if req.query.limit? and typeof req.query.limit == "number" then req.query.limit else 1000
        retsHelper.getDataDump mlsConfig, limit
        .then (list) ->
          resObj = new ExpressResponse(list)
          resObj.format = "csv"
          next resObj
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500

  getLookupTypes: (req, res, next) ->
    mlsConfigService.getById(req.params.mlsId)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
          404
      else
        retsHelper.getLookupTypes mlsConfig, req.params.databaseId, req.params.lookupId
        .then (list) ->
          next new ExpressResponse(list)
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500