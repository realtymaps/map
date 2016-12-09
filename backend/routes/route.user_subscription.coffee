_ = require 'lodash'
logger = require('../config/logger').spawn("route.user_subscription")
auth = require '../utils/util.auth'
paymentTransforms = require('../utils/transforms/transforms.payment')
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

  setPlan:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      userSubscriptionService.setPlan req.session.userid, req.params.plan

  getSubscription:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      userSubscriptionService.getSubscription req.session.userid

  deactivate:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      userSubscriptionService.deactivate req.session.userid
