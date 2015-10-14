_ = require 'lodash'
logger = require '../config/logger'
auth = require '../utils/util.auth'
rulesService = require '../services/service.dataSourceRules'
crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class RuleCrud extends crudHelpers.RouteCrud
  getRules: (req, res, next) =>
    @handleQuery @svc.getRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType).catch(_.partial(@onError, next)), res

  createRules: (req, res, next) =>
    @handleQuery @svc.createRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.body).catch(_.partial(@onError, next)), res

  putRules: (req, res, next) =>
    @handleQuery @svc.putRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.body).catch(_.partial(@onError, next)), res

  deleteRules: (req, res, next) =>
    @handleQuery @svc.deleteRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType).catch(_.partial(@onError, next)), res


  getListRules: (req, res, next) =>
    @handleQuery @svc.getListRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list).catch(_.partial(@onError, next)), res

  createListRules: (req, res, next) =>
    @handleQuery @svc.createListRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.body).catch(_.partial(@onError, next)), res

  putListRules: (req, res, next) =>
    @handleQuery @svc.putListRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.body).catch(_.partial(@onError, next)), res

  deleteListRules: (req, res, next) =>
    @handleQuery @svc.deleteListRules(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list).catch(_.partial(@onError, next)), res


  getRule: (req, res, next) =>
    @handleQuery @svc.getRule(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering).catch(_.partial(@onError, next)), res

  updateRule: (req, res, next) =>
    @handleQuery @svc.updateRule(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering, req.body).catch(_.partial(@onError, next)), res

  deleteRule: (req, res, next) =>
    @handleQuery @svc.deleteRule(req.params.dataSourceId, req.params.dataSourceType, req.params.dataListType, req.params.list, req.params.ordering).catch(_.partial(@onError, next)), res


module.exports = routeHelpers.mergeHandles new RuleCrud(rulesService),
  getRules:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  createRules:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  putRules:
    methods: ['put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deleteRules:
    methods: ['delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getListRules:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  createListRules:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  putListRules:
    methods: ['put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deleteListRules:
    methods: ['delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]

  getRule:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  updateRule:
    methods: ['patch']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  deleteRule:
    methods: ['delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
