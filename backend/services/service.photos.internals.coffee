Promise = require 'bluebird'
sharp = require 'sharp'
through2 = require 'through2'
errors = require '../utils/errors/util.errors.photos'
logger = require('../config/logger').spawn('service:photos:internals')

resize = ({stream, width, height}) -> new Promise (resolve, reject) ->

  interceptStream = stream
  resizeStream = sharp().resize(width, height)

  firstTime = true
  t2Transform = (chunk, enc, cb) ->
    if firstTime
      logger.debug 'pushing first chunk'
      firstTime = false
      resolve(resizeStream)
    logger.debug 'pushing chunk'
    @push chunk
    cb()

  t2Stream = through2 t2Transform, (cb) ->
    logger.debug 't2Transform'
    cb()

  handleError = (error) ->
    if firstTime
      reject error
    else
      logger.error 'Your in limbo. The stream has errored and we are not handling it correctly.'
      logger.error error

  interceptStream.once 'response', (response) ->
    logger.debug 'response received'
    if response.statusCode != 200
      handleError new errors.HttpStatusCodeError(response.statusCode, 'Not an Image due to error code ' + response.statusCode)
    if !response.headers['content-type'].match /image/ig
      handleError new errors.BadContentTypeError 'not an image, content type is ' + response.headers['content-type']

  interceptStream.once 'error', handleError

  interceptStream.pipe(t2Stream).pipe(resizeStream)

module.exports = {
  resize
}
