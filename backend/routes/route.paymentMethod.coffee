logger = require('../config/logger').spawn("route:paymentMethod")
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
      l = logger.spawn("root")
      l.debug -> "hit"
      paymentSourcesSvc.getAll(req.session.userid)

  getDefault:
    method: "get"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      l = logger.spawn("getDefault")
      l.debug -> "hit"
      paymentSourcesSvc.getDefault(req.session.userid)

  replaceDefault:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      l = logger.spawn("replaceDefault")
      l.debug -> "hit"
      validateAndTransformRequest(req, paymentTransforms.source)
      .then (validReq) ->
        paymentSourcesSvc.replaceDefault(req.session.userid, validReq.params.source)

  #all routes below are byId / :source same route, using different Http verbs
  add:
    method: "post"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      l = logger.spawn("add")
      l.debug -> "hit"
      validateAndTransformRequest(req, paymentTransforms.source)
      .then (validReq) ->
        paymentSourcesSvc.add(req.session.userid, validReq.params.source)

  remove:
    method: "delete"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      l = logger.spawn("remove")
      l.debug -> "hit"
      validateAndTransformRequest(req, paymentTransforms.source)
      .then (validReq) ->
        paymentSourcesSvc.remove(req.session.userid, validReq.params.source)


  setDefault:
    method: "put"
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      l = logger.spawn("setDefault")
      l.debug -> "hit"
      validateAndTransformRequest(req, paymentTransforms.source)
      .then (validReq) ->
        paymentSourcesSvc.setDefault(req.session.userid, validReq.params.source)
