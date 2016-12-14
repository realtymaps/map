_ = require 'lodash'
Archiver = require 'archiver'
through = require 'through2'
logger = require('../config/logger').spawn('util:mls:photos')
eventLogger = require('../config/logger').spawn('util:mls:photos:event')
logger = require('../config/logger').spawn('util:mls:photos')
photoErrors = require '../utils/errors/util.errors.photos'
analyzeValue = require '../../common/utils/util.analyzeValue'
request = require 'request'


imageEventTransform = () ->
  everSentData = false
  imageId = 0

  # coffeelint: disable=check_scope
  transform = (event, enc, cb) ->
  # coffeelint: enable=check_scope
    try

      if event?.error?
        eventLogger.debug -> "data event has an error #{analyzeValue.getFullDetails(event.error)}"
        #NOTE this should be a RetsError
        cb(event.error)
        return

      listingId = event.headerInfo.contentId
      fileExt = event.headerInfo.contentType.replace('image/','')
      location = event.headerInfo.location
      fileName = "#{listingId}_#{imageId}.#{fileExt}"

      event.extra = {fileExt,fileName,imageId,listingId}

      if location?
        event.extra.makeDataStream = () ->
          logger.debug -> 'calling event.extra.makeDataStream'
          request(location)

      imageId++
      everSentData = true

      @push(event)
      return cb()
    catch error
      return cb(new photoErrors.ObjectsStreamError(error))

  flush = (cb) ->
    if !everSentData
      eventLogger.debug -> "Error: Finished Events Transform with no object events"
      return cb(new photoErrors.NoPhotoObjectsError 'No object events')
    eventLogger.debug -> "Finished Events Transform"
    cb()

  through.obj(transform, flush)


toPhotoStream = (retsPhotoObject) ->
  retsPhotoObject.objectStream
  .pipe(imageEventTransform())


###
  Return a single image stream which is either a direct dataStream or cached location stream.

  The immediate returnable stream is used to track if the image stream is empty.
###
imageStream = (photoObject) ->
  l = logger.spawn("imageStream")
  l.debug -> "photoObject"
  l.debug -> _.omit photoObject, "objectStream"

  retStream = through()

  toPhotoStream(photoObject).once 'data', (event) ->

    stream = if event.dataStream
      l.debug -> "event.dataStream"
      event.dataStream
    else if event.extra.makeDataStream #YAY it is cached for us already
      l.debug -> "event.makeDataStream"
      event.extra.makeDataStream()
    else
      l.debug -> "event has no dataStream"
      through()

    stream.pipe(retStream)

  return retStream


imagesStream = (photoObject, archive = Archiver('zip')) ->
  l = logger.spawn("imagesStream")
  l.debug -> "photoObject"
  l.debug -> _.omit photoObject, "objectStream"
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
    l.error err
    retStream.emit('error', new photoErrors.ArchiveError(err))

  toArchive = (event, enc, cb) ->
    try
      if event.dataStream?
        l.debug -> "event.dataStream fileName: #{event.extra.fileName}"
        archive.append(event.dataStream, name: event.extra.fileName)

      if event.extra.makeDataStream?
        l.debug -> "event.extra.makeDataStream() fileName: #{event.extra.fileName}"
        archive.append(event.extra.makeDataStream(), name: event.extra.fileName)

      l.debug -> "finish appending fileName: #{event.extra.fileName}"
      cb()
    catch error
      cb(new photoErrors.ArchiveError(error))


  flush = (cb) ->
    try
      archive.finalize()
      l.debug -> "Archive wrote #{archive.pointer()} bytes"
      cb()
    catch error
      cb(new photoErrors.ArchiveError(error))


  toPhotoStream(photoObject)
  .pipe(through.obj(toArchive,flush))

  archive.pipe(retStream)

  return retStream


module.exports = {
  imageEventTransform
  toPhotoStream
  imagesStream
  imageStream
}
