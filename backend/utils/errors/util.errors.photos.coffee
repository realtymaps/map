NamedError = require './util.error.named'
httpStatus = require '../../../common/utils/httpStatus'

class PhotoError extends NamedError

class HttpStatusCodeError extends PhotoError
  constructor: (statusCode, args...) ->
    super('HttpStatusCodeError', args...)
    @returnStatus = statusCode

class BadContentTypeError extends PhotoError
  constructor: (args...) ->
    super('BadContentTypeError', args...)
    @returnStatus = httpStatus.UNSUPPORTED_MEDIA_TYPE

class ArchiveError extends PhotoError
  constructor: (args...) ->
    super('ArchiveError', args...)

class NoPhotoObjectsError extends PhotoError
  constructor: (args...) ->
    super('NoPhotoObjectsError', args...)
    @returnStatus = httpStatus.NOT_FOUND

class ObjectsStreamError extends PhotoError
  constructor: (args...) ->
    super('ObjectsStreamError', args...)

isNotFound = (err) ->
  if !err?
    return false

  err instanceof NoPhotoObjectsError || err instanceof BadContentTypeError

module.exports = {
  PhotoError
  HttpStatusCodeError
  BadContentTypeError
  ArchiveError
  NoPhotoObjectsError
  ObjectsStreamError
  isNotFound
}
