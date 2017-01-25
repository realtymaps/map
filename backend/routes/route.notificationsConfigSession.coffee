# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:notifications:config")
# coffeelint: enable=check_scope
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
notifcationConfigService = require('../services/service.notification.config').instance
auth = require '../utils/util.auth'
{validators} = require '../utils/util.validation'
{mergeHandles} = require '../utils/util.route.helpers'

class NotificationConfigSessionRouteCrud extends RouteCrud
  constructor: (args...) ->
    super(args...)

    @byIdPOSTTransforms =
      params: validators.object isEmptyProtect: true
      query: validators.object isEmptyProtect: true
      body: validators.object subValidateSeparate:
        frequency_id: validators.integer()
        id: validators.integer()
        method_id: validators.integer()
        auth_user_id: validators.integer()

    @rootGETTransforms =
      params: validators.object isEmptyProtect: true
      query: validators.object isEmptyProtect: true
      body: validators.object validators.object subValidateSeparate:
        auth_user_id: validators.integer()

  # Restrict all queries and updates to the req.user.id only
  rootGET: ({req, res, next, lHandleQuery}) ->
    req.body.auth_user_id = req.user.id
    super({req, res, next, lHandleQuery})

  # since were locking this down to the session id, we just will use the rootPost
  # to route to byIdPOST to do upserts
  rootPOST: ({req, res, next, lHandleQuery}) ->
    req.body.auth_user_id = req.user.id
    #update only, if we need inserts do a new route with admin permissions
    @byIdPUT({req, res, next, lHandleQuery})


module.exports = mergeHandles new NotificationConfigSessionRouteCrud(notifcationConfigService, enableUpsert:true),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
