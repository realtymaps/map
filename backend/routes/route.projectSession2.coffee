auth = require '../utils/util.auth'
ProjectSvc = require('../services/service.user.project')
logger = require '../config/logger'
{mergeHandles} = require '../utils/util.route.helpers'
safeProjectCols = (require '../utils/util.sql.helpers').columns.project

ProjectRouteCrud = require '../routeCrud/route.crud.projectSession2'

module.exports = mergeHandles new ProjectRouteCrud(ProjectSvc, undefined, 'ProjectRouteCrud').init(false, safeProjectCols),
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
