_ = require 'lodash'
logger = require('../config/logger').spawn("route.user_subscription")
auth = require '../utils/util.auth'
subscriptionTransforms = require('../utils/transforms/transforms.subscription')
{validateAndTransformRequest} = require '../utils/util.validation'
userSubscriptionService = require '../services/service.user_subscription'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'


handles = wrapHandleRoutes handles:
  
  getPlan: (req) ->
    userSubscriptionService.getPlan(req.session.userid)

  updatePlan: (req) ->
    console.log "\n\n###############################\nroute setPlan()"
    console.log "req.params:\n#{JSON.stringify(req.params)}"

    validateAndTransformRequest(req, subscriptionTransforms.updatePlan)
    .then (validReq) ->
      console.log "\n\nvalidReq:\n#{JSON.stringify(validReq,null,2)}\n\n"
      userSubscriptionService.updatePlan req.session.userid, validReq.params.plan

    # need to update our current session subscription status
    .then (subscriptionInfo) ->
      req.session.subscription = subscriptionInfo.status
      return subscriptionInfo.updated

  getSubscription: (req) ->
    userSubscriptionService.getSubscription req.session.userid

  reactivate: (req) ->
    console.log "\n\nreactivate()"
    console.log "req.session.subscription:#{req.session.subscription}"
    validateAndTransformRequest(req, subscriptionTransforms.reactivation)
    .then (validReq) ->
      console.log "validReq:\n#{JSON.stringify(validReq)}"
      userSubscriptionService.reactivate req.session.userid

    # need to update our current session subscription status
    .then (subscriptionInfo) ->
      req.session.subscription = subscriptionInfo.status
      return subscriptionInfo.created

  deactivate: (req) ->
    console.log "\n\ndeactivate()"
    console.log "req.session.subscription:#{req.session.subscription}"
    validateAndTransformRequest(req, subscriptionTransforms.deactivation)
    .then (validReq) ->
      userSubscriptionService.deactivate req.session.userid, validReq.body.reason


module.exports = mergeHandles handles,
  getPlan:
    method: "get"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  updatePlan:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireSubscriber()
    ]
  getSubscription:
    method: "get"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  reactivate:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deactivate:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireSubscriber()
    ]
