Promise = require 'bluebird'
# config = require '../config/config'
logger = require('../config/logger').spawn('service.photos')
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
sharp = require 'sharp'
through2 = require 'through2'

useOriginalImage = ({newSize, originalSize}) ->
  (!newSize?.width? || !newSize?.height?) ||
  (!originalSize?.width? || !originalSize?.height?) ||
  (Number(newSize.width) == Number(originalSize.width) && Number(newSize.height) == Number(originalSize.height))

useOriginalImagePromise = (opts) -> Promise.try () ->
  {newSize, data_source_id, originalSize} = opts

  if !newSize? or !data_source_id?
    logger.debug "GTFO: newSize: #{newSize}, data_source_id: #{data_source_id}"
    return Promise.resolve(true)

  if originalSize?
    logger.debug "GTFO: already have originalSize"
    return Promise.resolve useOriginalImage {originalSize, newSize}

  tables.config.mls()
  .where id: data_source_id
  .then (rows) ->
    {photoRes} = sqlHelpers.expectSingleRow(rows).listing_data
    logger.debug photoRes
    useOriginalImage {originalSize: photoRes, newSize}

resize = ({stream, width, height}) -> new Promise (resolve, reject) ->

  interceptStream = stream
  resizeStream = sharp().resize(width, height)

  firstTime = true
  t2Transform = (chunk, enc, cb) ->
    if firstTime
      firstTime = false
      resolve(resizeStream)
    @push chunk
    cb()

  t2Stream = through2 t2Transform, (cb) ->
    cb()

  handleError = (error) ->
    if firstTime
      reject error
    else
      logger.error 'Your in limbo. The stream has errored and we are not handling it correctly.'
      logger.error error

  interceptStream.once 'response', (response) ->
    if response.statusCode != 200
      handleError new Error 'bad statusCode'
    if !response.headers['content-type'].match /image/ig
      handleError new Error 'not an image'

  interceptStream.once 'error', handleError

  interceptStream.pipe(t2Stream).pipe(resizeStream)

module.exports = {
  resize
  useOriginalImage
  useOriginalImagePromise
}
