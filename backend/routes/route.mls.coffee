retsCache = require '../services/service.retsCache'
ExpressResponse = require '../utils/util.expressResponse'
logger = require('../config/logger').spawn('routes:mls')
mlsService = require '../services/service.mls'
{validators, validateAndTransformRequest} = require '../utils/util.validation'
auth = require '../utils/util.auth'
{handleRoute} =  require '../utils/util.route.helpers'
internals = require './route.mls.internals'

lookupMlsTransforms =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    state: validators.string(minLength:2, maxLength:2)
    full_name: validators.string(minLength:2)
    mls: validators.string(minLength:2)
    id: validators.integer()

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
      retsCache.getDatabaseList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getObjectList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      retsCache.getObjectList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getTableList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      retsCache.getTableList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getPhotos:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.getQueryPhoto({req, res, next})

  getParamsPhotos:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.getParamPhoto({req, res, next})

  getColumnList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      retsCache.getColumnList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getDataDump:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.getDataDump(req.params.mlsId, req.query)
      .then (csvPayload) ->
        resObj = new ExpressResponse(csvPayload)
        resObj.format = 'csv'
        resObj.filename = req.params.mlsId.toLowerCase() + '_mlsdata.csv'
        next(resObj)

  getLookupTypes:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      retsCache.getLookupTypes(req.params)
      .then (list) ->
        next new ExpressResponse(list)
