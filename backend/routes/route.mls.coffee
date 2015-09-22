_ = require 'lodash'
retsHelpers = require '../utils/util.retsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
mlsConfigService = require '../services/service.mls_config'
validation = require '../utils/util.validation'
auth = require '../utils/util.auth'

fs = require 'fs'

module.exports =
  getDatabaseList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then (mlsConfig) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getDatabaseList mlsConfig
          .then (list) ->
            next new ExpressResponse(list)
          .catch (error) ->
            next new ExpressResponse
              alert:
                msg: error.message
              500

  getTableList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then (mlsConfig) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getTableList mlsConfig, req.params.databaseId
          .then (list) ->
            next new ExpressResponse(list)
          .catch (error) ->
            next new ExpressResponse
              alert:
                msg: error.message
              500

  getColumnList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then (mlsConfig) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getColumnList mlsConfig, req.params.databaseId, req.params.tableId
          .then (list) ->

            # console #### remove 
            fs.writeFile '/tmp/ColumnList.txt', "mlsConfig: #{JSON.stringify(mlsConfig)}, databaseId: #{req.params.databaseId}, id: #{req.params.tableId}\n", (err) ->
              if err
                console.log "#### lookuptypes error:"
                console.log err
            for l in list
              fs.appendFile '/tmp/ColumnList.txt', "#{JSON.stringify(l)}\n", (err) ->
                if err
                  console.log "#### lookuptypes error:"
                  console.log err

            next new ExpressResponse(list)
          .catch (error) ->
            next new ExpressResponse
              alert:
                msg: error.message
              500

  getDataDump:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle:(req, res, next) ->
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
            retsHelpers.getDataDump mlsConfig, limit
            .then (rawList) ->
              # incoming column names can be arcane and technical, let's humanize them
              humanList = []
              retsHelpers.getColumnList mlsConfig, mlsConfig.listing_data.db, mlsConfig.listing_data.table
              .then (fields) ->
                # map the arcane (system) field names to human readable (longname) names
                readableMap = {}
                for field in fields
                  readableMap[field.SystemName] = field.LongName
                # populate human list with mapped names
                humanList = ((_.mapKeys row, (v, k) -> return readableMap[k]) for row in rawList)

              .then (humanList) ->
                resObj = new ExpressResponse(humanList)
                resObj.format = 'csv'
                next resObj
          .catch (error) ->
            next new ExpressResponse
              alert:
                msg: error.message
              500

  getLookupTypes:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then (mlsConfig) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getLookupTypes mlsConfig, req.params.databaseId, req.params.lookupId
          .then (list) ->

            # console #### remove 
            fs.writeFile '/tmp/LookupTypesList.txt', "mlsConfig: #{JSON.stringify(mlsConfig)}, databaseId: #{req.params.databaseId}, id: #{req.params.lookupId}\n", (err) ->
              if err
                console.log "#### lookuptypes error:"
                console.log err
            for l in list
              fs.appendFile '/tmp/LookupTypesList.txt', "#{JSON.stringify(l)}\n", (err) ->
                if err
                  console.log "#### lookuptypes error:"
                  console.log err

            next new ExpressResponse(list)
          .catch (error) ->
            next new ExpressResponse
              alert:
                msg: error.message
              500
