Promise = require 'bluebird'
request = require 'request'
_ =  require 'lodash'
sharp = require 'sharp'
# config = require '../config/config'
logger = require('../config/logger').spawn('service.photos')
tables = require '../config/tables'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
sqlHelpers = require '../utils/util.sql.helpers'

getMetaData = (opts) -> Promise.try () ->
  onMissingArgsFail
    args: opts
    required: ['data_source_id', 'data_source_uuid','photo_id', 'image_id']

  query = tables.property.combined()
  .where _.omit opts, 'image_id'

  logger.debug query.toString()

  query.then (rows) ->
    row = sqlHelpers.expectSingleRow(rows)
    photo = row?.photos?[opts.image_id]
    logger.debug photo
    photo

getRawPayload = (opts) ->
  getMetaData(opts)
  .then (meta) -> Promise.try ->
    if !meta?.url
      throw new Error 'meta.url is not found!'

    stream: request(meta.url)
    meta: meta

_useOriginalImage = ({newSize, originalSize}) ->
  (!newSize?.width? || !newSize?.height?) ||
  (!originalSize?.width? || !originalSize?.height?) ||
  (Number(newSize.width) == Number(originalSize.width) && Number(newSize.height) == Number(originalSize.height))

_useOriginalImagePromise = (opts) -> Promise.try () ->
  {newSize, data_source_id} = opts

  if !newSize? or !data_source_id?
    logger.debug "GTFO: newSize: #{newSize}, data_source_id: #{data_source_id}"
    return Promise.resolve(true)

  tables.config.mls()
  .where id: data_source_id
  .then (rows) ->
    {photoRes} = sqlHelpers.expectSingleRow(rows).listing_data
    logger.debug photoRes
    _useOriginalImage {originalSize: photoRes, newSize}

getResizedPayload = (opts) -> Promise.try () ->
  {width, height} = opts
  newSize = {width, height}

  getRawPayload(_.omit opts, Object.keys newSize)
  .then (payload) ->
    stream = payload.stream
    meta = payload.meta

    _useOriginalImagePromise
      newSize: newSize
      data_source_id: opts.data_source_id
    .then (doUseOriginal) ->

      logger.debug "doUseOriginal: #{doUseOriginal}"

      if !doUseOriginal
        logger.debug "resizing to width: #{width}, height: #{height}"
        stream = payload.stream.pipe(sharp().resize(width, height))
        meta = _.extend {}, payload.meta, {width, height}

      stream: stream
      meta: meta


module.exports = {
  getRawPayload
  getMetaData
  getResizedPayload
}
