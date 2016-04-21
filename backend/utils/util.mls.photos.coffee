logger = require('../config/logger').spawn('util.mls.photos')
_ = require 'lodash'
Archiver = require 'archiver'
through = require 'through2'

_hasNoStar = (photoIds) ->
  JSON.stringify(photoIds).indexOf('*') == -1

isSingleImage = (photoIds) ->
  if _.isString(photoIds)
    return true
  if _.keys(photoIds).length == 1 and _hasNoStar(photoIds)
    return true
  false

###
  using through2 to return a stream now which eventually has data pushed to it
  via event.dataStream
###
imageStream = (object) ->
  error = null

  #immediate returnable stream
  retStream = through (chunk, enc, callback) ->
    if !chunk && !everSentData
      return callback new Error 'No object events'

    if error?
      return callback(error)

    @push chunk
    callback()

  everSentData = false
  #as data MAYBE comes in push it to the returned stream
  object.objectStream.on 'data', (event) ->
    if event.error
      return error = event.error

    logger.debug event.headerInfo
    everSentData = true
    event.dataStream.pipe(retStream)

  retStream

imagesHandle = (object, cb, doThrowNoEvents = false) ->
  everSentData = false
  imageId = 0

  object.objectStream.on 'data', (event) ->

    return if event?.error?

    logger.debug event.headerInfo
    listingId = event.headerInfo.contentId
    fileExt = event.headerInfo.contentType.replace('image/','')
    contentType = event.headerInfo.contentType

    everSentData = true
    fileName = "#{listingId}_#{imageId}.#{fileExt}"
    logger.debug "fileName: #{fileName}"

    payload = {data: event.dataStream, name: fileName, imageId, contentType}

    if event.headerInfo.objectData?
      payload.objectData = event.headerInfo.objectData

    imageId++
    cb(null, payload)

  object.objectStream.on 'end', () ->
    if !everSentData and doThrowNoEvents
      cb(new Error 'No object events')
    cb(null, null, true)

  return

imagesStream = (object, archive = Archiver('zip')) ->

  archive.on 'error', (err)  ->
    throw err

  imagesHandle object, (err, payload, isEnd) ->
    if(err)
      throw err

    if(isEnd)
      archive.finalize()
      logger.debug("Archive wrote #{archive.pointer()} bytes")
      return

    archive.append(payload.data, name: payload.name)


  archive


hasSameUploadDate = (uploadDate1, uploadDate2, allowNull = false) ->
  if allowNull && !uploadDate1? && !uploadDate2?
    return true

  uploadDate1? && uploadDate2? &&
    (new Date(uploadDate1)).getTime() == (new Date(uploadDate2)).getTime()

module.exports = {
  isSingleImage
  imagesHandle
  imagesStream
  imageStream
  hasSameUploadDate
}
