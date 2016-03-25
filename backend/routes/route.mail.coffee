auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
mailCampaignService = require '../services/service.mail_campaigns'
{validators} = require '../utils/util.validation'


reqTransforms =
  body:
    validators.reqId toKey: "auth_user_id"

class MailCampaignRoute extends RouteCrud
  getReviewDetails: (req, res, next) =>
    @custom @svc.getReviewDetails(req.user.id, req.params.id, req.body), res

  getProperties: (req, res, next) =>
    @custom @svc.getProperties(req.params.project_id, req.user.id), res

instance = new MailCampaignRoute mailCampaignService,
  debugNS: "mailRoute"
  reqTransforms: reqTransforms
  enableUpsert: true

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      # auth.requirePermissions({all:['add_','change_']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      # auth.requirePermissions({all:['add_','change_', 'delete_']}, logoutOnFail:true)
    ]
  getReviewDetails:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getProperties:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
