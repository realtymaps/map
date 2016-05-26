auth = require '../utils/util.auth'
ProjectSvcClass = require('../services/service.user.project')
logger = require '../config/logger'
{mergeHandles} = require '../utils/util.route.helpers'
safeProjectCols = require('../utils/util.sql.helpers').columns.project
tables = require '../config/tables'
ProjectRouteCrud = require './route.projectSession.internal'

projectSvc = new ProjectSvcClass(tables.user.project).init(false)

# routeCrud = new ProjectRouteCrud(new ProjectSvc(tables.user.project).init(false), undefined, 'ProjectRouteCrud').init(true, safeProjectCols)
routeCrud = new ProjectRouteCrud(projectSvc, undefined, 'ProjectRouteCrud').init(true, safeProjectCols)
merged = mergeHandles routeCrud,
  ##TODO: How much of the post, delete, and puts do we really want to allow?
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
      auth.requireProjectEditor(methods: 'post')
    ]
  clientsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  notes:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  notesById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  drawnShapes:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  drawnShapesById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]


merged.neighborhoods =
  middleware: [
    auth.requireLogin(redirectOnFail: true)
  ]
  handle: routeCrud.drawnShapesCrud.neighborhoods

module.exports = merged
