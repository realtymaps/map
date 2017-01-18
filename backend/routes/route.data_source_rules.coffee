# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:data_source_rules")
# coffeelint: enable=check_scope
auth = require '../utils/util.auth'
rulesService = require '../services/service.dataSourceRules'
crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'


class RuleCrud extends crudHelpers.RouteCrud
  getRules: (req, res, next) =>
    @handleQuery(
      @svc.getRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType)
      res)

  createRules: (req, res, next) =>
    @handleQuery(
      @svc.createRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.body)
      res)

  putRules: (req, res, next) =>
    @handleQuery(
      @svc.putRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.body)
      res)

  deleteRules: (req, res, next) =>
    @handleQuery(
      @svc.deleteRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType)
      res)


  getListRules: (req, res, next) =>
    @handleQuery(
      @svc.getListRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list)
      res)

  createListRules: (req, res, next) =>
    @handleQuery(
      @svc.createListRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list
        req.body)
      res)

  putListRules: (req, res, next) =>
    @handleQuery(
      @svc.putListRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list
        req.body)
      res)

  deleteListRules: (req, res, next) =>
    @handleQuery(
      @svc.deleteListRules(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list)
      res)


  getRule: (req, res, next) =>
    @handleQuery(
      @svc.getRule(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list
        req.params.ordering)
      res)

  updateRule: (req, res, next) =>
    @handleQuery(
      @svc.updateRule(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list
        req.params.ordering
        req.body)
      res)

  deleteRule: (req, res, next) =>
    @handleQuery(
      @svc.deleteRule(
        req.params.dataSourceId
        req.params.dataSourceType
        req.params.dataListType
        req.params.list
        req.params.ordering)
      res)


module.exports = routeHelpers.mergeHandles new RuleCrud(rulesService),
  getRules:
    methods: ['get']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  createRules:
    methods: ['post']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  putRules:
    methods: ['put']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  deleteRules:
    methods: ['delete']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  getListRules:
    methods: ['get']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  createListRules:
    methods: ['post']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  putListRules:
    methods: ['put']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  deleteListRules:
    methods: ['delete']
    middleware: [
      auth.requirePermissions('access_staff')
    ]

  getRule:
    methods: ['get']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  updateRule:
    methods: ['patch']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
  deleteRule:
    methods: ['delete']
    middleware: [
      auth.requirePermissions('access_staff')
    ]
