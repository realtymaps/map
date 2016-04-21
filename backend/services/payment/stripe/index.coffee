Promise = require 'bluebird'
stripeBootstrap = require './service.payment.impl.stripe.bootstrap'
logger = (require '../../../config/logger').spawn('stripe')
analyzeValue = require '../../../../common/utils/util.analyzeValue'

module.exports = Promise.try () ->
  stripeBootstrap
  .then (stripe) ->
    logger.info 'backend stripe is bootstraped'
    customers: require('./service.payment.impl.stripe.customers')(stripe)
    events: require('./service.payment.impl.stripe.events')(stripe)
    charges: require('./service.payment.impl.stripe.charges')(stripe)
  .catch (err) ->
    logger.error 'backend stripe is bootstraped failed'
    logger.error analyzeValue.getSimpleDetails(err)
