logger = require('../config/logger').spawn('util:route:mls')
ExpressResponse =  require './util.expressResponse'
retsService = require '../services/service.rets'
_ = require 'lodash'
photoUtil = require './util.mls.photos'
{PartiallyHandledError, isUnhandled} = require './errors/util.error.partiallyHandledError'
httpStatus = require '../../common/utils/httpStatus'
{RetsError} =  require 'rets-client'
require '../extensions/stream'


hasNoStar = (photoIds) ->
  JSON.stringify(photoIds).indexOf('*') == -1


isSingleImage = (photoIds) ->
  if _.isString(photoIds)
    return true
  if _.keys(photoIds).length == 1 and hasNoStar(photoIds)
    return true
  false


respond = ({stream, next, res}) ->
  stream
  .pipe(res)
  .once 'error', (error) ->
    if isUnhandled(error)
      error = new PartiallyHandledError(error, 'uncaught image streaming error (*** add better error handling code to cover this case! ***)')
    next new ExpressResponse(error.message, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: error.quiet, logError: error})


handleImage = ({res, next, object}) ->
  res.type object.headerInfo.contentType

  respond {
    res
    next
    stream: photoUtil.imageStream(object)
  }


handleImages = ({res, next, object, mlsId, photoIds}) ->
  listingIds = _.keys(photoIds).join('_')
  res.attachment("#{mlsId}_#{listingIds}_photos.zip")

  respond {
    res
    next
    stream: photoUtil.imagesStream(object)
  }


handleRetsObjectResponse = ({res, next, photoIds, mlsId, object}) ->
  opts = {res, next, photoIds, mlsId, object}

  logger.debug -> opts.object.headerInfo

  if isSingleImage(opts.photoIds)
    return handleImage(opts)
  handleImages(opts)


getPhoto = ({entity, res, next, photoType, objectsOpts}) ->
  logger.debug -> {entity, photoType, objectsOpts}

  {photoIds, mlsId, databaseId} = entity

  if photoIds == 'null' or photoIds  == 'empty'
    photoIds = null

  retsService.getPhotosObject({
    mlsId
    databaseName:databaseId
    photoIds
    photoType
    objectsOpts
  })
  .then (object) ->
    logger.debug -> "object"
    logger.debug -> object

    handleRetsObjectResponse({res, next, photoIds, mlsId, object})
    .toPromise()
  .catch RetsError, (error) ->
    error.returnStatus = httpStatus.NOT_FOUND
    throw error


module.exports = {
  hasNoStar
  isSingleImage
  respond
  handleImage
  handleImages
  handleRetsObjectResponse
  getPhoto
}
