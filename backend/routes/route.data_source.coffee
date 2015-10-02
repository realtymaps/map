_ = require 'lodash'
dataSourceService = require '../services/service.dataSource'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
auth = require '../utils/util.auth'


module.exports =
  getColumnList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      dataSourceService.getColumnList req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType
      .then (list) ->
        next new ExpressResponse(list)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500

  getLookupTypes:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      dataSourceService.getLookupTypes req.params.lookupId
      .then (list) ->
        next new ExpressResponse(list)
      .catch (error) ->
        next new ExpressResponse
          alert:
            msg: error.message
          500
