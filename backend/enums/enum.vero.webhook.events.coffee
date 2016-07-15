_ = require 'lodash'

events = ['sent', 'delivered', 'opened', 'clicked' , 'bounced', 'unsubscribed']

module.exports = _.indexBy events, (val) ->
  val
