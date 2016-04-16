dataSourceService = require '../services/service.dataSource'
auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class DataSourceCrud extends RouteCrud
  getColumnList: (req, res) =>
    data = @svc.getColumnList req.params.dataSourceId, req.params.dataListType
    @custom data, res

  getLookupTypes: (req, res) =>
    data = @svc.getLookupTypes req.params.dataSourceId, req.params.dataListType, req.params.lookupId
    @custom data, res


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
