logger = require('../config/logger').spawn("route:history:user")
historyUserSvc = require('../services/service.historyUser').instance
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'
# {validators} = require '../utils/util.validation'
routeHelpers = require '../utils/util.route.helpers'

class HistoryUserCrud extends RouteCrud


# Yay for the new style
instance = new HistoryUserCrud(historyUserSvc)

logger.debug -> "HistoryUserCrud instance created"

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
