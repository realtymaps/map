_ = require 'lodash'

module.exports = (array, doLen = true, id = 'rm_property_id') ->
  obj = _.indexBy array, id
  obj.length = array.length if doLen
  obj
