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

_useOriginalImage = (width, height, payload) ->
  (width == payload.meta.width &&  height == payload.meta.height) || (!width? and !height?)

getResizedPayload = (opts) -> Promise.try () ->
  toOmit = ['width', 'height']
  {width, height} = opts
  if (!width? and height?) or (!height? and width?)
    throw new Error('both width and height must be specified')
  getRawPayload(_.omit opts, toOmit)
  .then (payload) ->
    stream = payload.stream

    if !_useOriginalImage(width, height, payload)
      stream = payload.stream.pipe(sharp().resize(width, height))

    stream: stream
    meta: payload.meta


module.exports = {
  getRawPayload
  getMetaData
  getResizedPayload
}
