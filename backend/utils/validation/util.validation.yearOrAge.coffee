Promise = require 'bluebird'


module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value
      return null

    if value.year
      return {label: 'Year Built', value: value.year}
    else if value.age
      return {label: 'Age', value: value.age}
    else
      return null
