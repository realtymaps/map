logger = require('../config/logger').spawn("route:userFeedback")
userFeedbackSvc = require('../services/service.userFeedback').instance
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'
# {validators} = require '../utils/util.validation'
routeHelpers = require '../utils/util.route.helpers'

class UserFeedbackRouteCrud extends RouteCrud


# Yay for the new style
instance = new UserFeedbackRouteCrud(userFeedbackSvc)

logger.debug -> "UserFeedbackRouteCrud instance created"

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions('access_staff')
    ]
  byId:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions('access_staff')
    ]
