auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
mailCampaignService = require '../services/service.mail_campaigns'
{validators} = require '../utils/util.validation'
tableNames = require('../config/tableNames')
sqlHelpers = require '../utils/util.sql.helpers'


reqTransforms =
  body:
    validators.reqId toKey: "auth_user_id"

class MailCampaignRoute extends RouteCrud

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
