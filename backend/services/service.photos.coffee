Promise = require 'bluebird'
request = require 'request'
_ =  require 'lodash'
logger = require('../config/logger').spawn('service:photos')
tables = require '../config/tables'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
sqlHelpers = require '../utils/util.sql.helpers'
mlsConfigService = require './service.mls_config'
{NoPhotoObjectsError} = require '../utils/errors/util.errors.photos'
probe = require 'probe-image-size'

getMetaData = (opts) -> Promise.try () ->
  onMissingArgsFail
    args: opts
    required: ['data_source_id', 'data_source_uuid', 'image_id']

  query = tables.finalized.photo()
  .select('photos')
  .where _.pick opts, ['data_source_id', 'data_source_uuid']

  logger.debug query.toString()

  query.then (rows) ->
    rows = _.filter rows, (r) ->
      !!Object.keys(r.photos).length
    row = sqlHelpers.expectSingleRow(rows)
    meta = row?.photos?[opts.image_id]

    if !meta?.url
      throw new NoPhotoObjectsError(quiet: true, "Photo not found")

    # logger.debug meta
    meta

getResizedPayload = (opts) -> Promise.try () ->
  {width, height, data_source_id, data_source_uuid, image_id} = opts

  logger.debug "Photo request #{data_source_uuid}##{image_id} @ #{width||'?'}px x #{height||'?'}px"

  getMetaData(opts)

  .then (meta) ->
    probe(meta.url)

    .catch (err) ->
      logger.debug "Could not probe image size because:", err?.message
      return false # Will fallback to metadata or MLS

    .then (probeResult) ->
      logger.debug probeResult

      # Preferred way of determining image size
      if probeResult?.width && probeResult?.height
        logger.debug "Using probed photo for originalSize: #{probeResult.width} x #{probeResult.height}"
        meta.width = probeResult.width
        meta.height = probeResult.height
        return meta

      # Image-specific metadata exists, so use that
      else if meta.width? && meta.height?
        logger.debug "Using photo metadata for originalSize: #{meta.width} x #{meta.height}"
        return meta

      # Least desirable case, trust the MLS
      else
        return mlsConfigService.getByIdCached(data_source_id)
        .then (mlsInfo) ->
          if mlsInfo?.listing_data?.photoRes
            logger.debug "Using MLS photores for originalSize: #{mlsInfo.listing_data.photoRes.width} x #{mlsInfo.listing_data.photoRes.height}"
            meta.width = mlsInfo.listing_data.photoRes.width
            meta.height = mlsInfo.listing_data.photoRes.height
          else
            logger.debug "Could not get MLS photores for #{data_source_id}, is it configured?"
          return meta

    .catch (err) ->
      logger.warn err
      logger.warn "Could NOT get original size for photo because:", err?.message

    .then () ->
      # Note request() and pipe() must be called on the same tick
      stream = request(meta.url)

      _resize = (width, height) ->
        logger.debug "Resize from #{meta.width}px x #{meta.height}px -> #{width}px x #{height}px"
        if Number(width) != Number(meta?.width) || Number(height) != Number(meta?.height)
          logger.debug "Resizing to #{width}px x #{height}px"
          stream = stream.pipe((require 'sharp')().resize(width, height))
          meta = _.extend {}, meta, {width, height}
          #Using this method seems to cause 504 gateway timeout.
          # internals.resize {stream, width, height}
          # .then (resizeStream) ->
          #   stream = resizeStream
          #   meta = _.extend {}, meta, {width, height}
        else
          logger.debug "Resize unnecessary, streaming unmodified image"

      if meta?.width && meta?.height # we can get aspect
        aspect = meta.width / meta.height
        logger.debug "Aspect ratio:", aspect
        if width && !height
          _resize(width, Math.round(width/aspect))
        else if !width && height
          _resize(Math.round(height*aspect), height)
        else if width && height
          _resize(width, height)
        else
          logger.debug "No target size, streaming unmodified image"
      else if width && height # no originalSize, so resize only if width and height provided
        logger.debug "No aspect ratio, but we got both dimensions"
        _resize(width, height)
      else
        logger.debug "Cannot resize, streaming unmodified image"

      return {stream, meta}

module.exports = {
  getResizedPayload
}
