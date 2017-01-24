# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:paymentMethod")
# coffeelint: enable=check_scope
auth = require '../utils/util.auth'
paymentTransforms = require('../utils/transforms/transforms.payment')
{validateAndTransformRequest} = require '../utils/util.validation'

paymentSourcesSvc = require('../services/payment/stripe')().then ({sources}) ->
  paymentSourcesSvc = sources

module.exports =
  root:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      paymentSourcesSvc.getAll(req.session.userid)

  getDefault:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      paymentSourcesSvc.getDefault(req.session.userid)

  replaceDefault:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      validateAndTransformRequest(req, paymentTransforms.replaceDefaultSource)
      .then (validReq) ->
        paymentSourcesSvc.replaceDefault(req.session.userid, validReq.params.source)
