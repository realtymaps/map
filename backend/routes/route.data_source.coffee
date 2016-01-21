dataSourceService = require '../services/service.dataSource'
auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class DataSourceCrud extends RouteCrud
  getColumnList: (req, res) =>
    @svc.getColumnList(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType), res

  getLookupTypes: (req, res) =>
    @handleQuery @svc.getLookupTypes(req.params.dataSourceId, req.params.lookupId), res


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

# dataSourceService = require '../services/service.dataSource'
# auth = require '../utils/util.auth'
# crudHelpers = require '../utils/crud/util.crud.route.helpers'
# routeHelpers = require '../utils/util.route.helpers'


# class DataSourceCrud extends crudHelpers.RouteCrud
#   getColumnList: (req, res) =>
#     @handleQuery @svc.getColumnList(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType), res

#   getLookupTypes: (req, res) =>
#     @handleQuery @svc.getLookupTypes(req.params.dataSourceId, req.params.lookupId), res


# module.exports = routeHelpers.mergeHandles new DataSourceCrud(dataSourceService),
#   getColumnList:
#     methods: ['get']
#     middleware: [
#       auth.requireLogin(redirectOnFail: true)
#     ]
#   getLookupTypes:
#     methods: ['get']
#     middleware: [
#       auth.requireLogin(redirectOnFail: true)
#     ]
