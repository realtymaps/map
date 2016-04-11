Promise = require 'bluebird'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'
chargeService = null
require('../services/services.payment').then (svc) ->
  chargeService = svc.charges
  console.log "\n\nStripe online, charge keys:\n#{Object.keys(chargeService)}"



handles = wrapHandleRoutes handles:
  getHistory: (req) ->
    Promise.try () ->
      auth_user_id = req.session.userid
      console.log "auth_user_id:\n#{JSON.stringify(auth_user_id,null,2)}"
      return throw new Error "Stripe API not ready" if !chargeService
      chargeService.getHistory auth_user_id





module.exports = mergeHandles handles,
  getHistory: method: "get"
