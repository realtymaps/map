_ = require 'lodash'
logger = require('../config/logger').spawn("route.paymentMethod")
auth = require '../utils/util.auth'
paymentTransforms = require('../utils/transforms/transforms.payment')
{validateAndTransformRequest} = require '../utils/util.validation'
userSubscriptionService = require '../services/service.paymentMethod'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'

# routing, and restful auth for payment method operations
handles = wrapHandleRoutes handles:

  getPlan: (req) ->
    console.log "route.getPlan()"
    console.log "req.session:\n#{JSON.stringify(req.session,null,2)}"
    console.log "req.query:\n#{JSON.stringify(req.query,null,2)}"
    console.log "req.params:\n#{JSON.stringify(req.params,null,2)}"
    console.log "req.body:\n#{JSON.stringify(req.body,null,2)}"
    userSubscriptionService.getPlan(req.session.userId)

  setPlan: (req) ->
    console.log "route.setPlan()"
    console.log "req.session:\n#{JSON.stringify(req.session,null,2)}"
    console.log "req.query:\n#{JSON.stringify(req.query,null,2)}"
    console.log "req.params:\n#{JSON.stringify(req.params,null,2)}"
    console.log "req.body:\n#{JSON.stringify(req.body,null,2)}"
    userSubscriptionService.setPlan()

  # getDefaultSource: (req) ->
  #   paymentMethodService.getDefaultSource req.session.userid

  # replaceDefaultSource: (req) ->
  #   validateAndTransformRequest req, paymentTransforms.replaceDefaultSource
  #   .then (validReq) ->
  #     paymentMethodService.replaceDefaultSource req.session.userid, validReq.params.source

module.exports = mergeHandles handles,
  getPlan:
    method: "get"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  setPlan:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
