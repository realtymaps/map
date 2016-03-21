retsHelpers = require '../utils/util.retsHelpers'
ExpressResponse = require '../utils/util.expressResponse'
logger = require('../config/logger').spawn('backend:routes:mls')
mlsConfigService = require '../services/service.mls_config'
mlsService = require '../services/service.mls'
{validators, validateAndTransformRequest} = require '../utils/util.validation'
auth = require '../utils/util.auth'
Promise = require 'bluebird'
through2 = require 'through2'

{handleRoute} =  require '../utils/util.route.helpers'

lookupMlsTransforms =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    state: validators.string(minLength:2, maxLength:2)
    full_name: validators.string(minLength:2)
    mls: validators.string(minLength:2)
    id: validators.integer()

_handleRetsObject = (res, next, object) ->
  logger.debug object.headerInfo, true
  res.type object.headerInfo.contentType

  everSentData = false

  object.objectStream.on 'data', (event) ->
    if !event.error
      everSentData = true
      event.dataStream.pipe(res)

  object.objectStream.on 'end', () ->
    if !everSentData
      next new ExpressResponse 'No object events', 404

_getPhoto = ({req, res, next, photoType}) ->
  validateAndTransformRequest req,
    params: validators.object subValidateSeparate:
      photoIds: validators.string(minLength:2)
      mlsId: validators.string(minLength:2)
      databaseId: validators.string(minLength:2)
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
  .then (validReq) ->
    {photoIds, mlsId, databaseId} = validReq.params
    mlsConfigService.getById(mlsId)
    .then ([mlsConfig]) ->
      if !mlsConfig
        next new ExpressResponse
          alert:
            msg: "Config not found for MLS #{mlsId}, try adding it first"
          404
      else
        retsHelpers.getPhotosObject
          serverInfo:mlsConfig
          databaseName:databaseId
          photoIds: photoIds
          photoType: photoType
        .then _handleRetsObject.bind(null, res, next)
        .catch (error) ->
          next new ExpressResponse error, 500

module.exports =
  root:
    method: 'post'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        validateAndTransformRequest req, lookupMlsTransforms
        .then (validReq) ->
          logger.debug validReq
          mlsService.getAll(validReq.body)

  supported:
    method: 'post'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        validateAndTransformRequest req, lookupMlsTransforms
        .then (validReq) ->
          logger.debug validReq
          mlsService.getAllSupported(validReq.body)

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

  getPhotos:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) -> _getPhoto({req, res, next})

  getLargePhotos:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) -> _getPhoto({req, res, next, photoType: 'LargePhoto'})

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
            limit: [validators.integer(min: 1), validators.defaults(defaultValue: 1000)]
          validateAndTransformRequest(req.query, validations)
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
            resObj.filename = req.params.mlsId.toLowerCase() + '_mlsdata.csv'
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
