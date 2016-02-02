Case = require 'case'
_ = require 'lodash'

events = [
  "customer.creation"
  "customer.remove"
].map (name) ->
  'stripe.' + name

module.exports = _.indexBy events, (val) ->
  Case.camel(val)
