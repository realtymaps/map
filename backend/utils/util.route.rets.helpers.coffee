logger = require('../config/logger').spawn('util.route.rets.helpers')
ExpressResponse =  require './util.expressResponse'
{validators, validateAndTransformRequest} = require './util.validation'
retsHelpers = require './util.retsHelpers'
mlsConfigService = require '../services/service.mls_config'
_ = require 'lodash'
photoUtil = require './util.mls.photos'

_handleGenericImage = ({setContentTypeFn, getStreamFn, next, res}) ->
  setContentTypeFn()
  getStreamFn()
  .on 'error', (error) ->
    next new ExpressResponse error.message, 500
  .pipe(res)

_handleImage = ({res, next, object}) ->
  _handleGenericImage {
    res
    next
    setContentTypeFn: () ->
      res.type object.headerInfo.contentType
    getStreamFn: () ->
      photoUtil.imageStream(object)
  }

_handleImages = ({res, next, object, mlsId, photoIds}) ->
  _handleGenericImage {
    res
    next
    setContentTypeFn: () ->
      listingIds = _.keys(photoIds).join('_')
      res.attachment("#{mlsId}_#{listingIds}_photos.zip")
    getStreamFn: () ->
      photoUtil.imagesStream(object)
  }

handleRetsObjectResponse = (res, next, photoIds, mlsId, object) ->
  opts = {res, next, photoIds, mlsId, object}

  logger.debug opts.object.headerInfo, true

  if photoUtil.isSingleImage(opts.photoIds)
    return _handleImage(opts)
  _handleImages(opts)

_getPhoto = ({entity, res, next, photoType}) ->
  logger.debug entity

  {photoIds, mlsId, databaseId} = entity

  if photoIds == 'null' or photoIds  == 'empty'
    photoIds = null

  mlsConfigService.getById(mlsId)
  .then ([mlsConfig]) ->
    if !mlsConfig
      next new ExpressResponse
        alert:
          msg: "Config not found for MLS #{mlsId}, try adding it first"
        404
    else
      retsHelpers.getPhotosObject({
        serverInfo:mlsConfig
        databaseName:databaseId
        photoIds
        photoType
      })
      .then handleRetsObjectResponse.bind(null, res, next, photoIds, mlsId)
      .catch (error) ->
        next new ExpressResponse error, 500

getParamPhoto = ({req, res, next, photoType}) ->
  validateAndTransformRequest req,
    params: validators.object subValidateSeparate:
      photoIds: validators.string(minLength:2)
      mlsId: validators.string(minLength:2)
      databaseId: validators.string(minLength:2)
    query: validators.object subValidateSeparate:
      photoType: validators.string(minLength:2)
    body: validators.object isEmptyProtect: true
  .then (validReq) ->
    photoType = validReq.query.photoType || photoType

    _getPhoto({entity: validReq.params, res, next, photoType})

getQueryPhoto = ({req, res, next, photoType}) ->
  logger.debug "req.query"
  logger.debug req.query

  validateAndTransformRequest req,
    params: validators.object subValidateSeparate:
      mlsId: validators.string(minLength:2)
      databaseId: validators.string(minLength:2)
    query: validators.object subValidateSeparate:
      ids: validators.object(json:true)
      photoType: validators.string(minLength:2)
    body: validators.object isEmptyProtect: true
  .then (validReq) ->
    logger.debug "validReq.query"
    logger.debug validReq.query

    photoType = validReq.query.photoType || photoType
    _getPhoto({entity: _.merge(validReq.params, photoIds:validReq.query.ids), res, next, photoType})

module.exports = {
  handleRetsObjectResponse
  getQueryPhoto,
  getParamPhoto,
}
