retsCache = require '../services/service.retsCache'
ExpressResponse = require '../utils/util.expressResponse'
logger = require('../config/logger').spawn('routes:mls')
mlsService = require '../services/service.mls'
mlsAgentService = require '../services/service.mls.agent'
{validateAndTransformRequest, validateAndTransform} = require '../utils/util.validation'
auth = require '../utils/util.auth'
{handleRoute} =  require '../utils/util.route.helpers'
internals = require './route.mls.internals'
transforms = require '../utils/transforms/transforms.mls'
httpStatus = require '../../common/utils/httpStatus'

module.exports =
  root:
    method: 'post'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        validateAndTransformRequest req, transforms.lookup
        .then (validReq) ->
          logger.debug validReq
          mlsService.getAll(validReq.body)

  supported:
    method: 'post'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        validateAndTransformRequest req, transforms.lookup
        .then (validReq) ->
          logger.debug validReq
          mlsService.getAllSupported(validReq.body)

  supportedStates:
    method: 'get'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        mlsService.supported.getAllStates()

  activeAgent:
    method: 'post'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        logger.debug -> "req.body: #{JSON.stringify req.body}"
        validateAndTransform req, transforms.lookupAgent
        .then (validReq) ->
          logger.debug -> "@@@@ validReq @@@@"
          logger.debug -> validReq
          mlsAgentService.exists(validReq.body)
          .then (found) ->
            if found
              return found

            next new ExpressResponse(alert: {msg: "mls agent not found or active"}, {status: httpStatus.NOT_FOUND, quiet: true})




  supportedPossibleStates:
    method: 'get'
    handle: (req, res, next) ->
      handleRoute req, res, next, ->
        mlsService.supported.getPossibleStates()

  getDatabaseList:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      retsCache.getDatabaseList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getObjectList:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      retsCache.getObjectList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getTableList:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      retsCache.getTableList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  ###
  BEGIN PHOTOS
  NOTE:
  This comment's main intent is to distinguish the photo routes in route.mls.coffee.
  The routes for photos in route.mls.coffee are purley staff oriented non-cached photos
  talking directly to a specific mls system. Therefore, they are purley for debugging and setting
  up an MLS system for its photos.
  ###

  getPhotos:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      internals.getQueryPhoto({req, res, next})

  getParamsPhotos:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      internals.getParamPhoto({req, res, next})
  # END PHOTOS
  getColumnList:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      retsCache.getColumnList(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  getDataDump:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      internals.getDataDump(req.params.mlsId, req.params.dataType, req.query)
      .then (csvPayload) ->
        resObj = new ExpressResponse(csvPayload)
        resObj.format = 'csv'
        resObj.filename = "#{req.params.mlsId.toLowerCase()}_#{req.params.dataType}_data.csv"
        next(resObj)

  getLookupTypes:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      retsCache.getLookupTypes(req.params)
      .then (list) ->
        next new ExpressResponse(list)

  testOverlapSettings:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      internals.testOverlapSettings(req.params.mlsId)
      .then (result) ->
        next new ExpressResponse(result)
