Promise = require 'bluebird'
_ = require 'lodash'


# Current supported format options:
#
# options.deliminate
#   Format a value to contain commas
#
# options.addDollarSign
#   Append a `$` to a value to denote currency
#
module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->

    if !value? or value == ''
      return null

    numvalue = value

    # For numerical primitaves
    # Not advocating to precede `format` validator with a `float` or `integer` validator since
    #   `format` validator should be maintained to account for all data types as needed anyways
    if _.isFinite(Number(numvalue))
      numvalue = Number(numvalue)

      if options.deliminate
        # double check we have decimal
        decimalIndex = numvalue.toString().indexOf('.')
        minimumFractionDigits = undefined
        if decimalIndex > 0 # always shows a zero in whole part
          minimumFractionDigits = numvalue.toString().length - decimalIndex - 1
        numvalue = numvalue.toLocaleString('en', minimumFractionDigits: minimumFractionDigits)

    # all values (including strings that cant be cast to Number)
    if options.addDollarSign
      numvalue = "$#{numvalue}"

    return numvalue
