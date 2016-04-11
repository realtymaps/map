Promise = require 'bluebird'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'
chargeService = null
require('../services/services.payment').then (svc) ->
  chargeService = svc.charges


handles = wrapHandleRoutes handles:
  getHistory: (req) ->
    return throw new Error "Stripe API not ready" if !chargeService
    chargeService.getHistory req.session.userid

module.exports = mergeHandles handles,
  getHistory: method: "get"
