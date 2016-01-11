logger = require '../config/logger'
Promise = require 'bluebird'
stripeBootstrap = require './payment/service.payment.impl.stripe.bootstrap'

#PROMISED BASED MODULE
module.exports = Promise.try () -> stripeBootstrap.then (stripe) ->
  logger.info 'backend stripe is bootsraped'
  customers: require('./payment/service.payment.impl.stripe.customers')(stripe)
  event: require('./payment/service.payment.impl.stripe.events')(stripe)
