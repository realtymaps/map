NamedError = require './util.error.named'

class HttpStatusCodeError extends NamedError
  constructor: (@statusCode, args...) ->
    super('HttpStatusCodeError', args...)

class BadContentTypeError extends NamedError
  constructor: (args...) ->
    super('BadContentTypeError', args...)

class ArchiveError extends NamedError
  constructor: (args...) ->
    super('ArchiveError', args...)

class NoPhotoObjectsError extends NamedError
  constructor: (args...) ->
    super('NoPhotoObjectsError', args...)

class ObjectsStreamError extends NamedError
  constructor: (args...) ->
    super('ObjectsStreamError', args...)

module.exports = {
  HttpStatusCodeError
  BadContentTypeError
  ArchiveError
  NoPhotoObjectsError
  ObjectsStreamError
}
