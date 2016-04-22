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
      full: integerValidation()
      half: integerValidation()
      total: floatValidation()

  (param, value) -> Promise.try () ->
    if !value
      return null

    composite(param, value)
    .then (bareValues) ->
      if bareValues.full? && bareValues.half?
        result =
          label: 'Baths (Full / Half)'
          value: "#{bareValues.full} / #{bareValues.half}"
        result.filter = bareValues.full
        if bareValues.half > 0
          result.filter += 0.5
        return result
      else if bareValues.total?
        numStr = Math.floor(bareValues.total*10).toString()
        numStr = numStr[0...-1]+'.'+numStr[-1..]
        result =
          label: 'Baths'
          value: numStr
        result.filter = Math.floor(bareValues.total)
        if bareValues.total - result.filter > 0
          result.filter += 0.5
        return result
      else
        return null
