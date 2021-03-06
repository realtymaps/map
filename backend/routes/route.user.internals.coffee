Promise = require 'bluebird'
logger = require('../config/logger').spawn('route:user:internals')
{parseBase64} = require '../utils/util.image'
sizeOf = require 'image-size'
config = require '../config/config'
dimensionLimits = config.IMAGES.dimensions.profile
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
userInternalsSvc = require '../services/service.user.internals'
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'


_handleBlob = ({promise, res, next}) -> Promise.try ->
  promise.then (result) ->
    if !result?.blob?
      return next new ExpressResponse({} , {status: httpStatus.NOT_FOUND})

    parsed = parseBase64(result.blob)
    res.setHeader('Content-Type', parsed.type)
    buf = new Buffer(parsed.data, 'base64')
    dim = sizeOf buf
    if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
      logger.error "Dimensions of #{JSON.stringify dim} are outside of limits"
    res.send(buf)

getImage = ({res, next, entity}) ->
  _handleBlob {
    res
    promise: userInternalsSvc.getImage(entity)
    next
  }

getCompanyImage = (req, res, next) ->
  _handleBlob {
    res
    promise: userInternalsSvc.getImageByCompany req.user.company_id
    next
  }

getBlobFromReq = ({req, next}) ->
  # logger.debug req.body.blob
  if !req.body?.blob.contains('image/') || !req.body?.blob.contains('base64')
    throw new PartiallyHandledError({returnStatus: httpStatus.BAD_REQUEST}, 'image has incorrect formatting')

  if !req.body?
    throw new PartiallyHandledError({returnStatus: httpStatus.BAD_REQUEST}, 'undefined image blob')

  parsed = parseBase64(req.body.blob)
  buf = new Buffer(parsed.data, 'base64')
  dim = sizeOf buf

  if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
    throw new PartiallyHandledError({returnStatus: httpStatus.BAD_REQUEST}, "Dimensions of #{JSON.stringify dim} are outside of limits for user.id: #{req.user.id}")

  req.body.blob

updateImage = ({req, next, entity, context}) ->
  blob = getBlobFromReq({req, next})
  logger.debug "@@@@ entity @@@@"
  logger.debug -> entity

  userInternalsSvc.upsertImage({entity, blob, context})

updateCompanyImage = ({req, next, entity}) ->
  updateImage {
    req
    next
    entity
    context: 'company'
  }


module.exports = {
  getImage
  getCompanyImage
  getBlobFromReq
  updateImage
  updateCompanyImage
}
