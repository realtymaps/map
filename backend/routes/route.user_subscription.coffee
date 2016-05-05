_ = require 'lodash'
logger = require('../config/logger').spawn("route.user_subscription")
auth = require '../utils/util.auth'
paymentTransforms = require('../utils/transforms/transforms.payment')
{validateAndTransformRequest} = require '../utils/util.validation'
userSubscriptionService = require '../services/service.user_subscription'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'


handles = wrapHandleRoutes handles:
  
  getPlan: (req) ->
    userSubscriptionService.getPlan(req.session.userid)

  setPlan: (req) ->
    userSubscriptionService.setPlan req.session.userid, req.params.plan

  getSubscription: (req) ->
    userSubscriptionService.getSubscription req.session.userid

  deactivate: (req) ->
    userSubscriptionService.deactivate req.session.userid


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
  getSubscription:
    method: "get"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deactivate:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
