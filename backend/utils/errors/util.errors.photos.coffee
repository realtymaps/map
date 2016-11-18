NamedError = require './util.error.named'

class PhotoError extends NamedError

class HttpStatusCodeError extends PhotoError
  constructor: (@statusCode, args...) ->
    super('HttpStatusCodeError', args...)

class BadContentTypeError extends PhotoError
  constructor: (args...) ->
    super('BadContentTypeError', args...)

class ArchiveError extends PhotoError
  constructor: (args...) ->
    super('ArchiveError', args...)

class NoPhotoObjectsError extends PhotoError
  constructor: (args...) ->
    super('NoPhotoObjectsError', args...)

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
