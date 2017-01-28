logger = require('../config/logger').spawn("route:userFeedback:category")
svc = require('../services/service.userFeedbackCategory').instance
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'


class UserFeedbackCategoryRouteCrud extends RouteCrud

# Yay for the new style
instance = new UserFeedbackCategoryRouteCrud(svc)

logger.debug -> "UserFeedbackCategoryRouteCrud instance created"

module.exports =
  root:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
    handle: instance.root

  byId:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
    handle: instance.byId
