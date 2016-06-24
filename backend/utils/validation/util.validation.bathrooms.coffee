Promise = require 'bluebird'
integerValidation = require './util.validation.integer'
floatValidation = require './util.validation.float'
objectValidation = require './util.validation.object'


# goal of this validator is to prep for both display and filtering.  If we have separate full and half bath values,
# make it clear what's what.  If we don't, then display whatever combined value we have, which should look like
# whatever local realtors expect.  In either case, the filter value shoudl be the number of full baths, plus .5 if
# there is at least 1 half bath.  If we run into an MLS that differentiates quarter and 3-quarters baths, then we
# might need to add more to this.


module.exports = (options = {}) ->
  composite = objectValidation
    subValidateSeparate:
      full: integerValidation(implicitDecimals: options.implicit?.full)
      half: integerValidation(implicitDecimals: options.implicit?.half)
      total: floatValidation(implicitDecimals: options.implicit?.total)

  (param, value) -> Promise.try () ->
    if !value
      return null

    composite(param, value)
    .then (bareValues) ->
      {full, half, total} = bareValues
      if options.autodetect && half
        full = total
      if full? && half?
        result =
          label: 'Baths (Full / Half)'
          value: "#{full} / #{half}"
        result.filter = full
        if half > 0
          result.filter += 0.5
        return result
      else if total?
        numStr = Math.floor(total*10).toString()
        numStr = numStr[0...-1]+'.'+numStr[-1..]
        result =
          label: 'Baths'
          value: numStr
        result.filter = Math.floor(total)
        if total - result.filter > 0
          result.filter += 0.5
        return result
      else
        return null
