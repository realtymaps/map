Promise = require 'bluebird'
stripeBootstrap = require './service.payment.impl.stripe.bootstrap'
logger = (require '../../../config/logger').spawn('stripe')
analyzeValue = require '../../../../common/utils/util.analyzeValue'

module.exports = () -> Promise.try () ->
  stripeBootstrap()
  .then (bootstrapped) ->
    logger.info 'backend stripe is bootstrapped'
    customers: require('./service.payment.impl.stripe.customers')(bootstrapped)
    events: require('./service.payment.impl.stripe.events')(bootstrapped)
    charges: require('./service.payment.impl.stripe.charges')(bootstrapped)
    coupons: require('./service.payment.impl.stripe.coupons')(bootstrapped)
    sources: require('./service.payment.impl.stripe.sources')(bootstrapped)
    stripe: bootstrapped
  .catch (err) ->
    logger.error 'backend stripe is bootstrapped failed'
    logger.error analyzeValue.getFullDetails(err)
