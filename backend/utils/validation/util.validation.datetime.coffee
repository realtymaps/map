Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
moment = require 'moment'

fields = [
  'years'
  'months'
  'days'
  'hours'
  'minutes'
  'seconds'
  'milliseconds'
]

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null

    datetime = moment.utc(value, options.format, options.locale, options.strict)
    if !datetime.isValid()
      start = options.format.indexOf('D')
      if value.substr(start, 2) == '00'
        value = value.slice(0, start) + '01' + value.slice(start+2)

      datetime = moment.utc(value, options.format, options.locale, options.strict)
      if !datetime.isValid()
        return Promise.reject new DataValidationError("invalid data type given for date field (problem determining value for `#{fields[datetime.invalidAt()]}`)", param, value)

    if options.utcOffset
      datetime = datetime.utcOffset(options.utcOffset)

    if options.dateOnly
      datetime = datetime.startOf('day')
    return datetime._d  # get the underlying date object
