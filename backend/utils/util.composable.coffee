_ = require 'lodash'

module.exports =
  compose: (extensions...) ->
    args = [{}, @].concat extensions
    _.extend args...
