Promise = require "bluebird"
filterSummaryService = require '../../services/service.properties.filterSummary'
requestUtil = require '../../utils/util.http.request'
status = require '../../../common/utils/httpStatus'
logger = require '../../config/logger'


module.exports = 
  filterSummary: (req, res, next) ->
    Promise.try () ->
      filterSummaryService.getFilterSummary(req.query)
    .then (data) ->
      res.json(data)
    .catch requestUtil.query.ParamValidationError, (err) ->
      next(status: status.BAD_REQUEST, message: err.message)
    .catch (err) ->
      logger.error err.stack||err.toString()
      next(status: status.INTERNAL_SERVER_ERROR, message: err.message)
