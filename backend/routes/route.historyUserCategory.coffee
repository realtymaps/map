logger = require('../config/logger').spawn("route:history:user:category")
svc = require('../services/service.historyUserCategory').instance
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'


class HistoryUserCrudCategory extends RouteCrud

# Yay for the new style
instance = new HistoryUserCrudCategory(svc)

logger.debug -> "HistoryUserCrud instance created"

module.exports =
  root:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      instance.rootGET({req, res, next})

  rootPOST:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      instance.rootPOST({req, res, next})

  byIdGET:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      instance.byIdGET({req, res, next})

  byId:
    methods: ['post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
    handle: instance.byId
