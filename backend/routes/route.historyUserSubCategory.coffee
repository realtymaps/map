logger = require('../config/logger').spawn("route:history:user:sub:category")
svc = require('../services/service.historyUserSubCategory').instance
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'
# {validators} = require '../utils/util.validation'

class HistoryUserSubCrudCategory extends RouteCrud

# Yay for the new style
instance = new HistoryUserSubCrudCategory(svc)

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
