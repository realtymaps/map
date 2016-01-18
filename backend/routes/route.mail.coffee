auth = require '../utils/util.auth'
routeCrudHelpers = require '../utils/crud/util.crud.route.helpers'
svcCrudHelpers = require '../utils/crud/util.crud.service.helpers'
routeHelpers = require '../utils/util.route.helpers'
mailCampaignService = require '../services/service.mail_campaigns'
{validators} = require '../utils/util.validation'
tableNames = require('../config/tableNames')
sqlHelpers = require '../utils/util.sql.helpers'

class MailCampaignRouteCrud extends routeCrudHelpers.RouteCrud
  init: () ->
    @reqTransforms =
      params:
        validators.reqId toKey: "#{tableNames.mail.campaign}.auth_user_id"
      query:
        validators.mapKeys id: "#{tableNames.mail.campaign}.id"

    super arguments...

module.exports = routeHelpers.mergeHandles new MailCampaignRouteCrud(mailCampaignService, undefined, 'MailCampaignRouteCrud').init(true, sqlHelpers.columns.mailCampaigns),
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
