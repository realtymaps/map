retsHelper = require '../utils/util.mlsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
mlsConfigService = require '../services/service.mls_config'

module.exports =
  getDatabaseList: (req, res, next) ->
    logger.info 'mls.getDatabaseList', req.params.mlsId
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
    logger.info 'mls.getTableList', req.params.mlsId, req.params.databaseId
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
    logger.info 'mls.getColumnList', req.params.mlsId, req.params.databaseId, req.params.tableId
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
    logger.info 'mls.getDataDump', req.params.mlsId
    mlsConfigService.getById(req.params.mlsId)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
          404
      else
        console.log "#### mlsConfig"
        console.log mlsConfig
        retsHelper.getDataDump mlsConfig#, req.params.databaseId, req.params.tableId
        .then (list) ->
          # console.log "#### list:"
          # console.log list
          # res.attachment('testing.csv')
          resObj = new ExpressResponse(list)
          resObj.format = "csv"
          next resObj
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500
