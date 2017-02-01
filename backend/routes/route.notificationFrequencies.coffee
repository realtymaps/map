auth = require '../utils/util.auth'
tables = require '../config/tables'
{validators, validateAndTransformRequest} = require '../utils/util.validation'
logger = require('../config/logger').spawn('route:notification:methods')
_ = require 'lodash'

module.exports =
  root:
    middleware: [
      auth.requireLogin()
    ]
    handle: (req, res, next) ->
      l = logger.spawn("root")
      l.debug -> 'hit'

      validateAndTransformRequest req,
        params: validators.object isEmptyProtect: true
        body: validators.object isEmptyProtect: true
        query: validators.object subValidateSeparate:
          code_name: validators.string(minLength:1)
          name: validators.string(minLength:1)
      .then (tReq) ->
        l.debug -> "tReq"
        l.debug -> tReq

        q = tables.user.notificationFrequencies()
        if Object.keys(tReq.query).length
          _.each tReq.query, (v, k) ->
            q.where(k, 'like', "#{v}%")

        q.then (result) ->
          res.json(result)
