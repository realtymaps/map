hack = require '../utils/webpackHack.coffee'
window._ = hack.hiddenRequire 'lodash' unless window?._

codes =
  OK: 200
  ACCEPTED: 202
  BAD_REQUEST: 400
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
