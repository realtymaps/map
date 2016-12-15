# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route.user_subscription")
# coffeelint: enable=check_scope
auth = require '../utils/util.auth'
subscriptionTransforms = require('../utils/transforms/transforms.subscription')
{validateAndTransformRequest} = require '../utils/util.validation'
userSubscriptionService = require '../services/service.user_subscription'


module.exports =
  getPlan:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      userSubscriptionService.getPlan(req.session.userid)

  updatePlan:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireSubscriber() # avoid bouncing around on plans with this endpoint unless they're active/paid
    ]
    handle: (req) ->
      validateAndTransformRequest(req, subscriptionTransforms.updatePlan)
      .then (validReq) ->
        userSubscriptionService.updatePlan req.session.userid, validReq.params.plan

      # need to update our current session subscription status
      .then (subscriptionInfo) ->
        req.session.subscription = subscriptionInfo.status
        return subscriptionInfo.updated

  getSubscription:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      userSubscriptionService.getSubscription req.session.userid

  reactivate:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      validateAndTransformRequest(req, subscriptionTransforms.reactivation)
      .then (validReq) ->
        userSubscriptionService.reactivate req.session.userid

      # need to update our current session subscription status
      .then (subscriptionInfo) ->
        req.session.subscription = subscriptionInfo.status
        return subscriptionInfo.created

  deactivate:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireSubscriber()
    ]
    handle: (req) ->
      validateAndTransformRequest(req, subscriptionTransforms.deactivation)
      .then (validReq) ->
        userSubscriptionService.deactivate req.session.userid, validReq.body.reason
