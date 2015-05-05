Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
{getByFipsCode} = require('../services/service.cartodb').restful
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
_ = require 'lodash'
JSONStream = require 'JSONStream'

module.exports =
  getByFipsCode: (req, res, next) ->
    Promise.try ->
      # logger.debug(req, true)
      getByFipsCode(_.extend {}, req.params, req.query)
      .stream()
      .pipe(JSONStream.stringify())
      .pipe(res)
      # .then (data) ->
        # res.json(data)

    .catch (error) ->
      if _.isString error
        return next new ExpressResponse(alert: {msg: "#{error} for #{req.path}."}, httpStatus[error])
      throw error
