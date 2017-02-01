auth = require '../utils/util.auth'
{project} = require '../services/services.user'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

projectCrud = new RouteCrud(project)

module.exports = mergeHandles projectCrud,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['add_project','change_project']})
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['add_project','change_project','delete_project']})
    ]
