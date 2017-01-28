mlsConfigService = require '../services/service.mls_config'
auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class MlsConfigCrud extends RouteCrud
  updatePropertyData: (req, res, next) =>
    @custom @svc.updatePropertyData(req.params.id, req.body), res

  updateServerInfo: (req, res, next) =>
    @custom @svc.updateServerInfo(req.params.id, req.body), res


module.exports = routeHelpers.mergeHandles new MlsConfigCrud(mlsConfigService),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['add_mlsconfig','change_mlsconfig']})
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['add_mlsconfig','change_mlsconfig', 'delete_mlsconfig']})
    ]
  updatePropertyData:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['change_mlsconfig_mainpropertydata']}, logoutOnFail:false)
    ]
  updateServerInfo:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['change_mlsconfig_serverdata']}, logoutOnFail:false)
    ]
