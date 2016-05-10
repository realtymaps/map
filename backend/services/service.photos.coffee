Promise = require 'bluebird'
request = require 'request'
_ =  require 'lodash'
# config = require '../config/config'
logger = require('../config/logger').spawn('service.photos')
tables = require '../config/tables'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
sqlHelpers = require '../utils/util.sql.helpers'
internals = require './service.photos.internals'

getMetaData = (opts) -> Promise.try () ->
  onMissingArgsFail
    args: opts
    required: ['data_source_id', 'data_source_uuid', 'image_id']

  query = tables.property.combined()
  .where _.omit opts, 'image_id'
  .where 'photos', '!=', '{}'

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
  {width, height} = opts
  newSize = {width, height}

  getRawPayload(_.omit opts, Object.keys newSize)
  .then (payload) ->
    stream = payload.stream
    meta = payload.meta

    useOrigImageOpts =
      newSize: newSize
      data_source_id: opts.data_source_id

    if payload.meta?.width? && payload.meta?.height?
      logger.debug "using meta for originalSize"
      logger.debug payload.meta, true
      _.extend useOrigImageOpts, originalSize:
        width: payload.meta.width
        height: payload.meta.height

    internals.useOriginalImagePromise(useOrigImageOpts)
    .then (doUseOriginal) ->

      logger.debug "doUseOriginal: #{doUseOriginal}"

      if doUseOriginal
        return {stream, meta}

      logger.debug "resizing to width: #{width}, height: #{height}"

      internals.resize {stream, width, height}
      .then (stream) ->
        stream: stream
        meta: _.extend {}, payload.meta, {width, height}


module.exports = {
  getRawPayload
  getMetaData
  getResizedPayload
}
