_ = require 'lodash'
util = require 'util'
{expectSingleRow} = require '../utils/util.sql.helpers'
retsHelpers = require '../utils/util.retsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require('../config/logger').spawn('backend:routes:mls')
mlsConfigService = require '../services/service.mls_config'
validation = require '../utils/util.validation'
auth = require '../utils/util.auth'
Promise = require 'bluebird'
through2 = require 'through2'


module.exports =
  getDatabaseList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then ([mlsConfig]) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getDatabaseList mlsConfig
          .then (list) ->
            next new ExpressResponse(list)

  getTableList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then ([mlsConfig]) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getTableList mlsConfig, req.params.databaseId
          .then (list) ->
            next new ExpressResponse(list)

  getColumnList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then ([mlsConfig]) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getColumnList mlsConfig, req.params.databaseId, req.params.tableId
          .then (list) ->
            next new ExpressResponse(list)

  getDataDump:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle:(req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then ([mlsConfig]) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          validations =
            limit: [validation.validators.integer(min: 1), validation.validators.defaults(defaultValue: 1000)]
          validation.validateAndTransformRequest(req.query, validations)
          .then (result) ->
            retsHelpers.getDataStream(mlsConfig, result.limit)
          .then (retsStream) ->
            columns = null
            data = []
            new Promise (resolve, reject) ->
              delimiter = null
              csvStreamer = through2.obj (event, encoding, callback) ->
                switch event.type
                  when 'data'
                    data.push(event.payload[1..-1].split(delimiter))
                  when 'delimiter'
                    delimiter = event.payload
                  when 'columns'
                    columns = event.payload
                  when 'done'
                    resolve(data)
                    retsStream.unpipe(csvStreamer)
                    csvStreamer.end()
                  when 'error'
                    reject(event.payload)
                    retsStream.unpipe(csvStreamer)
                    csvStreamer.end()
                callback()
              retsStream.pipe(csvStreamer)
            .then () ->
              data: data
              options:
                columns: columns
                header: true
          .then (csvPayload) ->
            resObj = new ExpressResponse(csvPayload)
            resObj.format = 'csv'
            resObj.filename = 'mlsdata.csv'
            next(resObj)

  getLookupTypes:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then ([mlsConfig]) ->
        if !mlsConfig
          next new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getLookupTypes mlsConfig, req.params.databaseId, req.params.lookupId
          .then (list) ->
            next new ExpressResponse(list)
