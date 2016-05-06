photosService = require '../services/service.photos'
logger = require('../config/logger').spawn('route.photos')
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'
transforms = require '../utils/transforms/transforms.photos'
{validateAndTransformRequest} = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'

_getContentType = (payload) ->
  #Note: could save off content type in photos and duplicate lots of info

  splitted = payload.meta.url.split('.')
  fileExt = splitted[splitted.length - 1]
  "image/#{fileExt}"

handles = wrapHandleRoutes
  isDirect: true
  handles:
    getResized: (req, res, next) ->
      validateAndTransformRequest req, transforms.getResized
      .then (validReq) ->
        #TODO might want to consider an enum of width heights to allow

        logger.debug validReq, true

        photosService.getResizedPayload validReq.query
        .then (payload) ->
          contentType = _getContentType(payload)

          res.type = contentType
          res.setHeader 'Content-type', contentType

          if payload.meta.width
            res.setHeader 'X-ImageWidth', payload.meta.width

          if payload.meta.height
            res.setHeader 'X-ImageHeight', payload.meta.height

          ['uploadDate', 'description'].forEach (name) ->
            if payload.meta[name]
              res.setHeader "X-#{name}", payload.meta[name]

          logger.debug 'piping image'
          payload.stream.once 'error', (err) ->
            if res.headersSent
              return next new ExpressResponse(alert: {msg: err.message}, httpStatus.INTERNAL_SERVER_ERROR)

            res.status(httpStatus.INTERNAL_SERVER_ERROR)
            res.render 'error', alert: {msg: err.message}
          .pipe(res)



module.exports = mergeHandles handles,
  getResized: method: 'get'
