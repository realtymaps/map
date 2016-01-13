Promise = require 'bluebird'
stripeBootstrap = require './service.payment.impl.stripe.bootstrap'
logger = require '../../../config/logger'

module.exports = Promise.try () ->
  stripeBootstrap
  .then (stripe) ->
    logger.info 'backend stripe is bootsraped'
    customers: require('./service.payment.impl.stripe.customers')(stripe)
    events: require('./service.payment.impl.stripe.events')(stripe)
  .catch (err) ->
    logger.error 'backend stripe is bootsraped failed'
    logger.error err
