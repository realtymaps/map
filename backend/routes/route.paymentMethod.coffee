_ = require 'lodash'
logger = require('../config/logger').spawn("route.paymentMethod")
auth = require '../utils/util.auth'
paymentTransforms = require('../utils/transforms/transforms.payment')
{validateAndTransformRequest} = require '../utils/util.validation'
paymentMethodService = require '../services/service.paymentMethod'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'

# routing, and restful auth for payment method operations
handles = wrapHandleRoutes handles:
  getDefaultSource: (req) ->
    paymentMethodService.getDefaultSource req.session.userid

  replaceDefaultSource: (req) ->
    validateAndTransformRequest req, paymentTransforms.replaceDefaultSource
    .then (validReq) ->
      paymentMethodService.replaceDefaultSource req.session.userid, validReq.params.source

module.exports = mergeHandles handles,
  getDefaultSource:
    method: "get"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  replaceDefaultSource:
    method: "put"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
