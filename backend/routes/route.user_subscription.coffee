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
    validateAndTransformRequest(req, subscriptionTransforms.updatePlan)
    .then (validReq) ->
      userSubscriptionService.updatePlan req.session.userid, validReq.params.plan

    # need to update our current session subscription status
    .then (subscriptionInfo) ->
      req.session.subscription = subscriptionInfo.status
      return subscriptionInfo.updated

  getSubscription: (req) ->
    userSubscriptionService.getSubscription req.session.userid

  reactivate: (req) ->
    validateAndTransformRequest(req, subscriptionTransforms.reactivation)
    .then (validReq) ->
      userSubscriptionService.reactivate req.session.userid

    # need to update our current session subscription status
    .then (subscriptionInfo) ->
      req.session.subscription = subscriptionInfo.status
      return subscriptionInfo.created

  deactivate: (req) ->
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
