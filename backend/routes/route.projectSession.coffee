projectSvc = (require '../services/services.user').project
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth.coffee'
sqlHelpers = require '../utils/util.sql.helpers'
safeProject = sqlHelpers.columns.project

ProjectsSessionRouteCrud = require '../routeCrud/route.crud.projectSession'

module.exports = mergeHandles new ProjectsSessionRouteCrud(projectSvc).init(true, safeProject),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  clients:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  clientsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
