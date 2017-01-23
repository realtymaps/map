errors = require '../../../utils/errors/util.errors.stripe'
logger = require('../../../config/logger').spawn("stripe:coupons")

module.exports = (stripe) ->
  isValid = (stripe_coupon_id, doThrow = true) ->
    l = logger.spawn('isValid')

    stripe.coupons.retrieve(stripe_coupon_id)
    .then () ->
      true
    .catch (error) ->
      l.debug -> error
      if doThrow
        return throw new errors.InValidCouponError(error, "Bad Coupon code. No soup for you.")
      false

  isNoCreditCard = (stripe_coupon_id, doThrow = true) ->
    stripe.coupons.retrieve(stripe_coupon_id)
    .then (coupon) ->
      if coupon.metadata.noCreditCard != "true"
        if doThrow
          throw new errors.InValidCouponError('This coupon requires a credit card!')
        return false
      return true

  {
    isValid
    isNoCreditCard
  }
