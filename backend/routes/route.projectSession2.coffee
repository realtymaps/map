_ = require 'lodash'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user.coffee')
auth = require '../utils/util.auth'
ProjectSvc = require('../services/service.user.project')
{RouteCrud, hasManyRouteCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'
{mergeHandles} = require '../utils/util.route.helpers'

class ProjectRouteCrud extends RouteCrud
  @include userExtensions.route
  init: () ->
    @restrictAll @withUser
    @clientsCrud = hasManyRouteCrud(@svc.clients, 'id', 'project_id', 'ClientsHasManyRouteCrud')
    @clients = @clientsCrud.root
    @clientsById = @clientsCrud.byId

    @notesCrud = hasManyRouteCrud(@svc.notes, 'id', 'project_id', 'NotesHasManyRouteCrud')#.init(true)#to enable logging
    @notes = @notesCrud.root
    @notesById = @notesCrud.byId

    @drawnShapesCrud = hasManyRouteCrud(@svc.drawnShapes, 'id', 'project_id', 'DrawnShapesHasManyRouteCrud')
    @drawnShapes = @drawnShapesCrud.root
    @drawnShapesById = @drawnShapesCrud.byId
    super arguments...

safeProjectCols = (require '../utils/util.sql.helpers').columns.project
module.exports = mergeHandles new ProjectRouteCrud(ProjectSvc).init(true, safeProjectCols),
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
