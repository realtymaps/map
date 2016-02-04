Case = require 'case'
_ = require 'lodash'

events = [
  "customer.creation"
  "customer.remove"
  "customer.bad.card"
].map (name) ->
  'stripe.' + name

module.exports = _.indexBy events, (val) ->
  Case.camel(val)
