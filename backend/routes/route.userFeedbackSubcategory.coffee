logger = require('../config/logger').spawn("route:userFeedback:subcategory")
svc = require('../services/service.userFeedbackSubcategory').instance
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'
# {validators} = require '../utils/util.validation'

class UserFeedbackSubcategoryRouteCrud extends RouteCrud

# Yay for the new style
instance = new UserFeedbackSubcategoryRouteCrud(svc)

logger.debug -> "UserFeedbackSubcategoryRouteCrud instance created"

module.exports =
  root:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: instance.root

  byId:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: instance.byId
