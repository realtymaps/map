_ = require 'lodash'
dataSourceService = require '../services/service.dataSource'
logger = require '../config/logger'
auth = require '../utils/util.auth'
crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class DataSourceCrud extends crudHelpers.RouteCrud
  getColumnList: (req, res, next) =>
    @handleQuery @svc.getColumnList(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType).catch(_.partial(@onError, next)), res

  getLookupTypes: (req, res, next) =>
    @handleQuery @svc.getLookupTypes(req.params.lookupId).catch(_.partial(@onError, next)), res


module.exports = routeHelpers.mergeHandles new DataSourceCrud(dataSourceService),
  getColumnList:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getLookupTypes:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
