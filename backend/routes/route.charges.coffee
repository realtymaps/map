chargeService = null
require('../services/payment/stripe')().then (svc) ->
  chargeService = svc.charges

module.exports =
  getHistory:
    method: "get"
    handleQuery: true
    handle: (req) ->
      if !chargeService
        throw new Error "Stripe API not ready"
      chargeService.getHistory req.session.userid
