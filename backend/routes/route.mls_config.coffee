_ = require 'lodash'
mlsConfigService = require '../services/service.mls_config'
auth = require '../utils/util.auth'
crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class MlsConfigCrud extends crudHelpers.RouteCrud
  updatePropertyData: (req, res, next) =>
    @handleQuery @svc.updatePropertyData(req.params.id, req.body).catch(_.partial(@onError, next)), res

  updateServerInfo: (req, res, next) =>
    @handleQuery @svc.updateServerInfo(req.params.id, req.body).catch(_.partial(@onError, next)), res


module.exports = routeHelpers.mergeHandles new MlsConfigCrud(mlsConfigService),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_mlsconfig','change_mlsconfig']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_mlsconfig','change_mlsconfig', 'delete_mlsconfig']}, logoutOnFail:true)
    ]
  updatePropertyData:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_mlsconfig_mainpropertydata']}, logoutOnFail:false)
    ]
  updateServerInfo:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_mlsconfig_serverdata']}, logoutOnFail:false)
    ]
