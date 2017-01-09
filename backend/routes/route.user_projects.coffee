auth = require '../utils/util.auth'
{project} = require '../services/services.user'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

projectCrud = new RouteCrud(project)

module.exports = mergeHandles projectCrud,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_project','change_project']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_project','change_project','delete_project']}, logoutOnFail:true)
    ]
