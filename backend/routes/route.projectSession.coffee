auth = require '../utils/util.auth'
ProjectSvcClass = require('../services/service.user.project')
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:projectSession")
# coffeelint: enable=check_scope
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
      auth.requireLogin()
      auth.requireSubscriber(methods: 'post')
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
      auth.requireProjectEditor(methods: ['put', 'post', 'delete'])
    ]
  clients:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
      auth.requireProjectEditor(methods: 'post')
    ]
  clientsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
    ]
  notes:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
    ]
  notesById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
    ]
  drawnShapes:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
    ]
  drawnShapesById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
    ]


merged.areas =
  middleware: [
    auth.requireLogin()
  ]
  handle: routeCrud.drawnShapesCrud.areas

module.exports = merged
