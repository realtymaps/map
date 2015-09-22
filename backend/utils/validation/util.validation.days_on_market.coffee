pickFirstValidation = require './util.validation.pickFirst'
integerValidation = require './util.validation.integer'

module.exports = (options = {}) ->
  pickFirstValidation(criteria: integerValidation())
