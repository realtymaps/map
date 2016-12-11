Archiver = require 'archiver'
through = require 'through2'
logger = require('../config/logger').spawn('util:mls:photos')
payloadLogger = require('../config/logger').spawn('util:mls:photos:payload')
eventLogger = require('../config/logger').spawn('util:mls:photos:event')
logger = require('../config/logger').spawn('util:mls:photos')
photoErrors = require '../utils/errors/util.errors.photos'
analyzeValue = require '../../common/utils/util.analyzeValue'
request = require 'request'

###
  Return a single image stream which is either a direct dataStream or cached location stream.

  The immediate returnable stream is used to track if the image stream is empty.
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
  object.objectStream.once 'data', (event) ->
    if event.error
      return error = event.error

    eventLogger.debug -> event.headerInfo
    everSentData = true

    stream = if event.dataStream
      event.dataStream
    else if event.headerInfo.location #YAY it is cached for us already
      request(event.headerInfo.location)
    else
      through()

    stream.pipe(retStream)

  retStream


imagesHandle = (object, cb, doThrowNoEvents = false) ->
  everSentData = false
  imageId = 0

  object.objectStream.once 'error', (error) ->
    try
      # logger.debug "error event received"
      cb(new photoErrors.ObjectsStreamError(error))
    catch err
      logger.debug -> analyzeValue.getFullDetails(err)
      throw err

  object.objectStream.on 'data', (event) ->

    try
      # eventLogger.debug "data event received"

      if event?.error?
        eventLogger.debug -> "data event has an error #{analyzeValue.getFullDetails(event.error)}"
        cb(event.error)
        return

      eventLogger.debug -> "event"
      eventLogger.debug -> event
      listingId = event.headerInfo.contentId
      fileExt = event.headerInfo.contentType.replace('image/','')
      contentType = event.headerInfo.contentType
      location = event.headerInfo.location

      everSentData = true
      fileName = "#{listingId}_#{imageId}.#{fileExt}"

      # not handling event.dataStream.once 'error' on purpose
      # this makes it easier to discern overall errors vs individual photo error
      payload = {data: event.dataStream, name: fileName, imageId, contentType, location}

      if payload.location?
        eventLogger.makeData = () ->
          logger.debug -> 'calling makeData'
          request(payload.location)

      if event.headerInfo.objectData?
        payload.objectData = event.headerInfo.objectData

      imageId++
      cb(null, payload)
    catch err
      eventLogger.debug -> analyzeValue.getFullDetails(err)
      throw err

  object.objectStream.once 'end', () ->
    try
      # logger.debug "end event received"
      if !everSentData and doThrowNoEvents
        # logger.debug "end event received -- callback with NoPhotoObjectsError"
        cb(new photoErrors.NoPhotoObjectsError 'No object events')
      # logger.debug "end event received -- no NoPhotoObjectsError"
      cb(null, null, true)
    catch err
      logger.debug analyzeValue.getFullDetails(err)
      throw err


imagesStream = (object, archive = Archiver('zip')) ->

  ###
    Example: Chunked Response to download images directly
    ===========================================
     retsVersion: 'RETS/1.7.2',
     contentType: 'multipart/parallel; boundary="FLEXmYAyiXwGY1E4dlWSd9AQllVeyTEr76nECY088ghM661fGttsmo";charset=US-ASCII',
     transferEncoding: 'chunked'
  ###

  ###
    Example: Object Stream of Events of location URLS
    ===========================================
     retsVersion: 'RETS/1.7.2',
     contentType: 'multipart/parallel; boundary="FLEXrE2BqYPB4un1rgf1yc3iUHJ7dQkY3zo1MIiC1Cl66ldbQNjeRj";charset=US-ASCII',
     contentLength: '7476'
  ###

  retStream = through()

  archive.once 'error', (err)  ->
    retStream.emit('error', new photoErrors.ArchiveError(err))

  #pump images through the archive
  imagesHandle object, (err, payload, isEnd) ->
    if err
      return retStream.emit('error', err)

    if isEnd
      archive.finalize()
      payloadLogger.debug("Archive wrote #{archive.pointer()} bytes")
      return

    payloadLogger.debug -> "payload"
    payloadLogger.debug -> payload

    if payload.data?
      archive.append(payload.data, name: payload.name)

    if payload.location?
      payloadLogger.debug -> 'payload.location'
      archive.append(payload.makeData(), name: payload.name)


  archive.pipe(retStream)


module.exports = {
  imagesHandle
  imagesStream
  imageStream
}
