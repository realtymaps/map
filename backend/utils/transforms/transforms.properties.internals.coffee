_ = require 'lodash'
{validators} = require '../util.validation'


minMaxFilterValidations =
  price: [validators.string(replace: [/[$,]/g, ""]), validators.integer()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.float()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]
  closeDate: validators.datetime(dateOnly: true)

minMaxFilterValidations = _.transform minMaxFilterValidations, (result, validators, name) ->
  result["#{name}Min"] = validators
  result["#{name}Max"] = validators


module.exports = {
  minMaxFilterValidations
}
