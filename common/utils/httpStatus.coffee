hack = require '../utils/webpackHack.coffee'

codes =
  OK: 200
  ACCEPTED: 202
  BAD_REQUEST: 400
  UNAUTHORIZED: 401
  PAYMENT_REQUIRED: 402
  NOT_FOUND: 404
  INTERNAL_SERVER_ERROR: 500

okRange = (codes.BAD_REQUEST - 1) - codes.OK

isOK = (code) ->
  code == codes.OK

isWithinOK = (code) ->
  code - codes.OK < okRange

module.exports =
  _.extend codes,
    isOK: isOK
    isWithinOK: isWithinOK
