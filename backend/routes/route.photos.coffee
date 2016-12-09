photosService = require '../services/service.photos'
logger = require('../config/logger').spawn('route:photos')
transforms = require '../utils/transforms/transforms.photos'
{validateAndTransformRequest} = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
{HttpStatusCodeError, BadContentTypeError, NoPhotoObjectsError} = require '../utils/errors/util.errors.photos'
ExpectedSingleRowError = require '../utils/errors/util.error.expectedSingleRow'
config = require '../config/config'
{PartiallyHandledError, isUnhandled, QuietlyHandledError, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'

### NOTE:

This route is the main route used for photos to get a cached photo from our system!
Therefore a CDN caches images from here as well.

This comment's main intent is to distinguish the photo routes in route.mls.coffee.
The routes for photos in route.mls.coffee are purley staff oriented non-cached photos
talking directly to a specific mls system. Therefore, they are purley for debugging and setting
up an MLS system for its photos.
###

_getContentType = (meta) ->
  #Note: could save off content type in photos and duplicate lots of info

  splitted = meta.url.split('.')
  fileExt = splitted[splitted.length - 1]
  "image/#{fileExt}"

module.exports =
  getResized:
    handle: (req, res, next) ->
      validateAndTransformRequest req, transforms.getResized
      .then (validReq) ->
        #TODO might want to consider an enum of width heights to allow

        logger.debug validReq, true

        photosService.getResizedPayload validReq.query
        .then ({stream, meta}) ->
          contentType = _getContentType(meta)

          res.type = contentType
          res.setHeader 'Content-type', contentType
          res.setHeader 'Cache-Control', "public, max-age=#{config.FRONTEND_ASSETS.MAX_AGE_SEC}"

          if meta.width
            res.setHeader 'X-ImageWidth', meta.width

          if meta.height
            res.setHeader 'X-ImageHeight', meta.height

          ['uploadDate', 'description'].forEach (name) ->
            if meta[name]
              res.setHeader "X-#{name}", meta[name]

          logger.debug 'piping image'

          # this error is a worst case scenario if all the promise pre-streaming catches miss an exception
          # so the error here would likley be an error in the resize processing
          stream
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
      .catch isCausedBy(HttpStatusCodeError), (err) ->
        next new ExpressResponse(alert: {msg: err.message}, {status: err.statusCode, quiet: err.quiet})
      .catch isCausedBy(BadContentTypeError), (err) ->
        next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.UNSUPPORTED_MEDIA_TYPE, quiet: err.quiet})
      .catch isCausedBy(NoPhotoObjectsError), isCausedBy(ExpectedSingleRowError), (err) ->
        next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.NOT_FOUND, quiet: err.quiet})
