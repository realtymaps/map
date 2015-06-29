_ = require 'lodash'
retsHelper = require '../utils/util.mlsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
mlsConfigService = require '../services/service.mls_config'
validation = require '../utils/util.validation'

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
        #limit = if req.query.limit? and !isNaN req.query.limit then req.query.limit else 1000
        validations = 
          limit: [validation.validators.integer(min: 1), validation.validators.defaults(defaultValue: 1000)]
        validation.validateAndTransform(req.query, validations)
        .then (result) ->
          limit = result.limit
          retsHelper.getDataDump mlsConfig, limit
          .then (rawList) ->
            # incoming column names can be arcane and technical, let's humanize them
            humanList = []
            retsHelper.getColumnList mlsConfig, mlsConfig.main_property_data.db, mlsConfig.main_property_data.table
            .then (fields) ->
              # map the arcane (system) field names to human readable (longname) names
              readableMap = {}
              for field in fields
                readableMap[field.SystemName] = field.LongName
              # populate human list with mapped names
              humanList = ((_.mapKeys row, (v, k) -> return readableMap[k]) for row in rawList)

            .then (humanList) ->
              resObj = new ExpressResponse(humanList)
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