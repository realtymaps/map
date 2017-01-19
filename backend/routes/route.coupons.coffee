#logger = require('../config/logger').spawn("route.onboarding")
{validateAndTransformRequest} = require '../utils/util.validation'
transforms =  require '../utils/transforms/transforms.coupons'
paymentServices = require('../services/payment/stripe')().then (svc) ->
  paymentServices = svc

module.exports =
  isValid:
    method: "get"
    handleQuery: true
    handle: (req, res, next) ->
      validateAndTransformRequest(req, transforms.isValid)
      .then (validReq) ->
        if !validReq.query.isSpecial
          return paymentServices.coupons.isValid(validReq.query.stripe_coupon_id)

        paymentServices.coupons.isNoCreditCard(validReq.query.stripe_coupon_id)
