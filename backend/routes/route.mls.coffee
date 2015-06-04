retsHelper = require '../utils/util.mlsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
mlsConfigService = require '../services/service.mls_config'

module.exports =
  getDatabaseList: (req, res, next) ->
    logger.info 'mls.getDatabaseList', req.params.id
    mlsConfigService.getById(req.params.id)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.id}, try adding it first"
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
    logger.info 'mls.getTableList', req.params.id
    mlsConfigService.getById(req.params.id)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.id}, try adding it first"
          404
      else
        retsHelper.getTableList mlsConfig, req.params.databaseName
        .then (list) ->
          next new ExpressResponse(list)
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500

  getColumnList: (req, res, next) ->
    logger.info 'mls.getColumnList', req.params.id
    mlsConfigService.getById(req.params.id)
    .then (mlsConfig) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{req.params.id}, try adding it first"
          404
      else
        retsHelper.getColumnList mlsConfig, req.params.databaseName, req.params.tableName
        .then (list) ->
          next new ExpressResponse(list)
        .catch (error) ->
          next new ExpressResponse
            alert:
              msg: error.message
            500
