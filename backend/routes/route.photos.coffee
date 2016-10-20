photosService = require '../services/service.photos'
logger = require('../config/logger').spawn('route:photos')
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'
transforms = require '../utils/transforms/transforms.photos'
{validateAndTransformRequest} = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
{HttpStatusCodeError, BadContentTypeError} = require '../utils/errors/util.errors.photos'
config = require '../config/config'
ExpectedSingleRowError =  require '../utils/errors/util.error.expectedSingleRow'
{PartiallyHandledError, isUnhandled, QuietlyHandledError} = require '../utils/errors/util.error.partiallyHandledError'


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
          res.setHeader 'Cache-Control', "public, max-age=#{config.FRONTEND_ASSETS.MAX_AGE_SEC}"

          if payload.meta.width
            res.setHeader 'X-ImageWidth', payload.meta.width

          if payload.meta.height
            res.setHeader 'X-ImageHeight', payload.meta.height

          ['uploadDate', 'description'].forEach (name) ->
            if payload.meta[name]
              res.setHeader "X-#{name}", payload.meta[name]

          logger.debug 'piping image'

          # this error is a worst case scenario if all the promise pre-streaming catches miss an exception
          # so the error here would likley be an error in the resize processing
          payload.stream
          .once 'error', (err) ->
            if res.headersSent
              return next err # not using Express response since headers are already sent
            if isUnhandled(err)
              if err.message == 'Input buffer contains unsupported image format'
                err = new QuietlyHandledError(err, 'unsupported image format or no image found')
              else
                err = new PartiallyHandledError(err, 'uncaught photo stream error (*** add better error handling code to cover this case! ***)')
            next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})
          .pipe(res)
      .catch HttpStatusCodeError, (err) ->
        next new ExpressResponse(alert: {msg: err.message}, {status: err.statusCode, quiet: err.quiet})
      .catch BadContentTypeError, (err) ->
        next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.UNSUPPORTED_MEDIA_TYPE, quiet: err.quiet})
      .catch (err) ->
        next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.NOT_FOUND, quiet: err.quiet})



module.exports = mergeHandles handles,
  getResized: method: 'get'
