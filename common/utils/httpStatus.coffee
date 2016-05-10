_ = require 'lodash'

codes =
  OK: 200
  ACCEPTED: 202
  BAD_REQUEST: 400
  UNAUTHORIZED: 401
  PAYMENT_REQUIRED: 402
  NOT_FOUND: 404
  UNSUPPORTED_MEDIA_TYPE: 415
  INTERNAL_SERVER_ERROR: 500

isOK = (code) ->
  code == codes.OK

isWithinOK = (code) ->
  code < codes.BAD_REQUEST

module.exports =
  _.extend codes,
    isOK: isOK
    isWithinOK: isWithinOK
