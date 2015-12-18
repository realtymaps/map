Promise = require 'bluebird'


module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value
      return null

    if value.batchseq
      return "#{value.batchid}_#{value.batchseq}"

    return value.batchid
