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
    required: ['data_source_id', 'data_source_uuid', 'image_id']

  query = tables.property.combined()
  .where _.pick opts, ['data_source_id', 'data_source_uuid']

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

getResizedPayload = (opts) -> Promise.try () ->
  {width, height, data_source_id, data_source_uuid, image_id} = opts

  logger.debug "Requested resize of photo #{data_source_uuid}##{image_id} to #{width||'?'}px x #{height||'?'}px"
  newSize = {width, height}

  getRawPayload(opts)
  .then (payload) ->

    {stream, meta} = payload

    Promise.try ->

      if payload.meta?.width? && payload.meta?.height?
        logger.debug "Using photo metadata for originalSize: #{payload.meta.width} x #{payload.meta.height}"
        originalSize =
          width: payload.meta.width
          height: payload.meta.height
      else
        tables.config.mls()
        .where id: data_source_id
        .then (rows) ->
          {photoRes} = sqlHelpers.expectSingleRow(rows).listing_data
          logger.debug "Using MLS photores for originalSize: #{photoRes.width} x #{payload.height}"
          photoRes

    .catch (err) ->
      logger.warn "Could NOT get original size for photo!"

    .then (originalSize) ->

      _resize = (width, height) ->
        if Number(width) != Number(originalSize?.width) || Number(height) != Number(originalSize?.height)
          logger.debug "Resizing to #{width}px x #{height}px"
          stream = payload.stream.pipe(sharp().resize(width, height))
          meta = _.extend {}, payload.meta, {width, height}

      Promise.try ->
        if originalSize?.width && originalSize?.height # we can get aspect
          aspect = originalSize.width / originalSize.height
          if width && !height
            _resize(width, Math.round(width/aspect))
          else if !width && height
            _resize(Math.round(height*aspect), height)
          else if width && height
            _resize(width, height)
        else if width && height # no originalSize, so resize only if width and height provided
          _resize(width, height)

      .catch (err) ->
        logger.warn "Could NOT resize photo!"

    .then ->
      stream: stream
      meta: meta

module.exports = {
  getRawPayload
  getMetaData
  getResizedPayload
}
