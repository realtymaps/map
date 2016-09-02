Promise = require 'bluebird'
logger = require('../config/logger').spawn('route.user.internals')
{parseBase64} = require '../utils/util.image'
sizeOf = require 'image-size'
config = require '../config/config'
dimensionLimits = config.IMAGES.dimensions.profile
transforms = require '../utils/transforms/transforms.user'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
validation = require '../utils/util.validation'
userInternalsSvc = require '../services/service.user.internals'
userCompanySvc = require '../services/service.user.company.coffee'


getImage = ({res, next, entity, typeStr = 'user'}) -> Promise.try ->
  userInternalsSvc.getImage(entity)
  .then (result) ->
    if !result?.blob?
      return next new ExpressResponse({} , {status: httpStatus.NOT_FOUND})

    parsed = parseBase64(result.blob)
    res.setHeader('Content-Type', parsed.type)
    buf = new Buffer(parsed.data, 'base64')
    dim = sizeOf buf
    if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
      logger.error "Dimensions of #{JSON.stringify dim} are outside of limits for entity.id: #{entity.id}; type: #{typeStr}"
    res.send(buf)

getCompanyImage = (req, res, next) ->
  validation.validateAndTransformRequest(req.params, transforms.image)
  .then (validParams) ->
    getImage {
      req
      res
      next
      entity: {account_image_id: validParams.account_image_id}
      typeStr: 'company'
    }

getBlobFromReq = ({req, next}) ->
  # logger.debug req.body.blob
  if !req.body?.blob.contains 'image/' or !req.body?.blob.contains 'base64'
    return next new ExpressResponse({alert: 'image has incorrect formatting.'} , {status: httpStatus.BAD_REQUEST})

  if !req.body?
    return next new ExpressResponse({alert: 'undefined image blob'} , {status: httpStatus.BAD_REQUEST})

  parsed = parseBase64(req.body.blob)
  buf = new Buffer(parsed.data, 'base64')
  dim = sizeOf buf

  if dim.width > dimensionLimits.width || dim.height > dimensionLimits.height
    return next new ExpressResponse({alert: "Dimensions of #{JSON.stringify dim} are outside of limits for user.id: #{req.user.id}"} , {status: httpStatus.BAD_REQUEST})

  req.body.blob

updateImage = ({req, next, entity, svc = userInternalsSvc}) ->
  blob = getBlobFromReq({req, next})
  svc.upsertImage(entity, blob)

updateCompanyImage = ({req, next, entity}) ->
  updateImage {
    req
    next
    entity
    svc: userCompanySvc
  }


module.exports = {
  getImage
  getCompanyImage
  getBlobFromReq
  updateImage
  updateCompanyImage
}
