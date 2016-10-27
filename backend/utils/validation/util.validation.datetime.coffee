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
  if options.format
    format = options.format
    match = /M+/.exec(format)
    if match
      monthStart = match.index
      monthLength = match[0].length
    match = /D+/.exec(format)
    if match
      dayStart = match.index
      dayLength = match[0].length
  else
    format = 'YYYY-MM-DD[T]HH:mm:ss'
    monthStart = 5
    monthLength = 2
    dayStart = 8
    dayLength = 2
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null
    fixedValue = value
    if fixedValue.substr(monthStart, 2) == '00'
      fixedValue = fixedValue.slice(0, monthStart) + '01' + fixedValue.slice(monthStart+monthLength)
    if fixedValue.substr(dayStart, 2) == '00'
      fixedValue = fixedValue.slice(0, dayStart) + '01' + fixedValue.slice(dayStart+dayLength)
    datetime = moment.utc(fixedValue, format, options.locale, options.strict)
    if !datetime.isValid()
      throw new DataValidationError("invalid data given for date field (problem determining value for `#{fields[datetime.invalidAt()]}` with format #{format})", param, value)

    if options.utcOffset
      datetime = datetime.utcOffset(options.utcOffset)

    if options.dateOnly
      datetime = datetime.startOf('day')

    if options.outputFormat && options.outputFormat != "none"
      return datetime.format(options.outputFormat)

    return datetime._d  # get the underlying date object
