_ = require 'lodash'
logger = require('../config/logger').spawn("route.paymentMethod")
auth = require '../utils/util.auth'
paymentTransforms = require('../utils/transforms/transforms.payment')
{validateAndTransformRequest} = require '../utils/util.validation'
paymentMethodService = require '../services/service.paymentMethod'

module.exports =
  getDefaultSource:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      paymentMethodService.getDefaultSource req.session.userid

  replaceDefaultSource:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      validateAndTransformRequest req, paymentTransforms.replaceDefaultSource
      .then (validReq) ->
        paymentMethodService.replaceDefaultSource req.session.userid, validReq.params.source
