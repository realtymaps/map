NamedError = require './util.error.named'

class InValidSaveType extends NamedError
  constructor: (args...) ->
    super('InValidSaveType', args...)

module.exports = {
  InValidSaveType
}
