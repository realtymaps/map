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

isMaybeTransientError = (code) ->
  # hand-picked from https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
  code in [401, 403, 408, 429, 440, 500, 502, 503, 504, 509, 520, 521, 522, 523, 524, 525, 526]

module.exports =
  _.extend codes, {isOK, isWithinOK, isMaybeTransientError}
