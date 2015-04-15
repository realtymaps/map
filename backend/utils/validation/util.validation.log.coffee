Promise = require "bluebird"
logger = require '../../config/logger'
analyzeValue = require '../../../common/utils/util.analyzeValue'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if options.tag?
      tag = " <#{options.tag}>"
    else
      tag = ''
    logger[options.level]("[**VALIDATION**]#{tag} #{param}: #{JSON.stringify(analyzeValue(value))}")
    return value
