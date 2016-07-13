util = require 'util'

module.exports = (value, {defaultValue, defaultOn}) ->
  if defaultValue?
    if Array.isArray(defaultOn)
      if defaultOn.indexOf(value) != -1
        return defaultValue
    else
      if value == null || value == undefined || value == ''
        return defaultValue
  switch (typeof value)
    when 'boolean'
      return value
    when 'number'
      if value == 1
        return true
      if value == 0
        return false
    when 'object'
      if value == null
        return false
    when 'string'
      lowerValue = value.toLowerCase()
      if lowerValue == 'true' || lowerValue == 'on' || lowerValue == '1'
        return true
      if lowerValue == 'false' || lowerValue == 'off' || lowerValue == '0'
        return false
    when 'undefined'
      return false
  throw new Error("Unexpected value: #{util.inspect(value)}")
