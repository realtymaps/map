_ = require 'lodash'
retsHelpers = require '../utils/util.retsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
mlsConfigService = require '../services/service.mls_config'
validation = require '../utils/util.validation'
auth = require '../utils/util.auth'
Promise = require 'bluebird'
through2 = require 'through2'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'


module.exports =
  getDatabaseList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      mlsConfigService.getById(req.params.mlsId)
      .then (mlsConfig) ->
        if !mlsConfig
          new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getDatabaseList mlsConfig
          .then (list) ->
            new ExpressResponse(list)
      .then (expressResponse) ->
        next(expressResponse)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)
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
          new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getTableList mlsConfig, req.params.databaseId
          .then (list) ->
            new ExpressResponse(list)
      .then (expressResponse) ->
        next(expressResponse)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)
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
          new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getColumnList mlsConfig, req.params.databaseId, req.params.tableId
          .then (list) ->
            new ExpressResponse(list)
      .then (expressResponse) ->
        next(expressResponse)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)
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
          new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          validations =
            limit: [validation.validators.integer(min: 1), validation.validators.defaults(defaultValue: 1000)]
          validation.validateAndTransform(req.query, validations)
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
            resObj
      .then (expressResponse) ->
        next(expressResponse)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)
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
          new ExpressResponse
            alert:
              msg: "Config not found for MLS #{req.params.mlsId}, try adding it first"
            404
        else
          retsHelpers.getLookupTypes mlsConfig, req.params.databaseId, req.params.lookupId
          .then (list) ->
            new ExpressResponse(list)
      .then (expressResponse) ->
        next(expressResponse)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500
