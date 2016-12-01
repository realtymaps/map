_ = require 'lodash'
Promise = require 'bluebird'


module.exports = (options = {}) ->
  nullifier =  (val) ->
    if val == options.value
      return null
    return val
  (param, value) -> Promise.try () ->
    if !value?
      return value
    if _.isArray(value)
      return _.map(value, nullifier)
    else if typeof(value) == 'object'
      return _.mapValues(value, nullifier)
    else
      return nullifier(value)
