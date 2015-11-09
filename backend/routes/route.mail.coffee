auth = require '../utils/util.auth'
routeCrudHelpers = require '../utils/crud/util.crud.route.helpers'
svcCrudHelpers = require '../utils/crud/util.crud.service.helpers'
routeHelpers = require '../utils/util.route.helpers'
mailCampaignService = require '../services/service.mail_campaigns'


module.exports = routeHelpers.mergeHandles new routeCrudHelpers.RouteCrud(mailCampaignService),
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