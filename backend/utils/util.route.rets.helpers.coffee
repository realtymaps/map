logger = require('../config/logger').spawn('util.route.rets.helpers')
ExpressResponse =  require './util.expressResponse'
{validators, validateAndTransformRequest} = require './util.validation'
retsHelpers = require './util.retsHelpers'
mlsConfigService = require '../services/service.mls_config'
_ = require 'lodash'
Archiver = require 'archiver'

_handleImage = ({res, next, object}) ->
  res.type object.headerInfo.contentType

  everSentData = false

  object.objectStream.on 'data', (event) ->
    if !event.error
      everSentData = true
      event.dataStream.pipe(res)

  object.objectStream.on 'end', () ->
    if !everSentData
      next new ExpressResponse 'No object events', 404

_handleImages = ({res, next, object, mlsId, photoIds}) ->
  listingIds = _.keys(photoIds).join('_')

  archive = Archiver('zip')

  archive.on 'error', (err)  ->
    next new ExpressResponse err.message, 500

  res.attachment("#{mlsId}_#{listingIds}_photos.zip")

  everSentData = false

  object.objectStream.on 'data', (event) ->
    if !event.error
      imageId = event.headerInfo.objectId
      listingId = event.headerInfo.contentId
      fileExt = event.headerInfo.contentType.replace('image/','')

      everSentData = true
      fileName = "#{listingId}_#{imageId}.#{fileExt}"
      logger.debug "fileName: #{fileName}"
      archive.append(event.dataStream, name: fileName)

  object.objectStream.on 'end', () ->
    archive.finalize()
    logger.debug("Archive wrote #{archive.pointer()} bytes")

    if !everSentData
      next new ExpressResponse 'No object events', 404

  archive.pipe(res)

_hasNoStar = (photoIds) ->
  JSON.stringify(photoIds).indexOf('*') == -1

_isSingleImage = (photoIds) ->
  if _.isString(photoIds)
    return true
  if _.keys(photoIds).length == 1 and _hasNoStar(photoIds)
    return true
  false

handleRetsObjectResponse = (res, next, photoIds, mlsId, object) ->
  opts = {res, next, photoIds, mlsId, object}

  logger.debug opts.object.headerInfo, true

  if _isSingleImage(opts.photoIds)
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
