_ = require 'lodash'
# logger = require '../config/logger'

parseBase64 = (imageStr) ->
  unless _.isString imageStr
    imageStr = (new Buffer(imageStr)).toString()

  matches = imageStr.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/)

  # logger.debug matches

  type: matches[1]
  data: if matches.length == 3 then matches[2] else undefined

module.exports =
  parseBase64: parseBase64
