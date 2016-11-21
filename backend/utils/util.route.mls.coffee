logger = require('../config/logger').spawn('routes:mls:internals')
ExpressResponse =  require './util.expressResponse'
validation = require './util.validation'
retsService = require '../services/service.rets'
_ = require 'lodash'
photoUtil = require './util.mls.photos'
{PartiallyHandledError, isUnhandled} = require './errors/util.error.partiallyHandledError'
httpStatus = require '../../common/utils/httpStatus'
photoErrors = require './errors/util.errors.photos'
RetsError =  require 'rets-client'


hasNoStar = (photoIds) ->
  JSON.stringify(photoIds).indexOf('*') == -1


isSingleImage = (photoIds) ->
  if _.isString(photoIds)
    return true
  if _.keys(photoIds).length == 1 and hasNoStar(photoIds)
    return true
  false


handleGenericImage = ({setContentTypeFn, getStreamFn, next, res}) ->
  setContentTypeFn()
  getStreamFn()
  .on 'error', (error) ->
    if isUnhandled(error)
      error = new PartiallyHandledError(error, 'uncaught image streaming error (*** add better error handling code to cover this case! ***)')
    next new ExpressResponse(error.message, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: error.quiet})
  .pipe(res)


handleImage = ({res, next, object}) ->
  handleGenericImage {
    res
    next
    setContentTypeFn: () ->
      res.type object.headerInfo.contentType
    getStreamFn: () ->
      photoUtil.imageStream(object)
  }


handleImages = ({res, next, object, mlsId, photoIds}) ->
  handleGenericImage {
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

  if isSingleImage(opts.photoIds)
    return handleImage(opts)
  handleImages(opts)


getPhoto = ({entity, res, next, photoType}) ->
  logger.debug entity

  {photoIds, mlsId, databaseId} = entity

  if photoIds == 'null' or photoIds  == 'empty'
    photoIds = null

  retsService.getPhotosObject({
    mlsId
    databaseName:databaseId
    photoIds
    photoType
  })
  .then (object) ->
    handleRetsObjectResponse(res, next, photoIds, mlsId, object)
  .catch validation.DataValidationError, (error) ->
    next new ExpressResponse(error.message||error, {status: httpStatus.BAD_REQUEST, quiet: error.quiet})
  .catch photoErrors.isNotFound, (error) ->
    next new ExpressResponse(error.message||error, {status: httpStatus.NOT_FOUND, quiet: error.quiet})
  .catch photoErrors.PhotoError, (error) ->
    next new ExpressResponse(error.message||error, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: error.quiet})
  .catch RetsError, (error) ->
    next new ExpressResponse(error.message||error, {status: httpStatus.NOT_FOUND, quiet: error.quiet})
  .catch (error) ->
    if isUnhandled(error)
      error = new PartiallyHandledError(error, 'uncaught photo error (*** add better error handling code to cover this case! ***)')
    next new ExpressResponse(error.message||error, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: error.quiet})


module.exports = {
  hasNoStar
  isSingleImage
  handleGenericImage
  handleImage
  handleImages
  handleRetsObjectResponse
  getPhoto
}
