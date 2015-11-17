_ = require 'lodash'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user.coffee')
auth = require '../utils/util.auth'
ProjectSvc = require('../services/service.user.project')
{routeCrud, RouteCrud, hasManyRouteCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'
{mergeHandles} = require '../utils/util.route.helpers'
usrTableNames = require('../config/tableNames').user
{joinColumnNames} = require '../utils/util.sql.columns'
{validators} = require '../utils/util.validation'

class ProjectRouteCrud extends RouteCrud
  init: () ->
    #replaces the need for restrictAll
    @reqTransforms =
      params: validators.reqId toKey: 'auth_user_id'

    @doLogQuery = ['query','params']
    @clientsCrud = routeCrud(@svc.clients, 'clients_id', 'ClientsHasManyRouteCrud', ['query','params'])
    @clientsCrud.byIdGETTransforms =
      query: validators.mapKeys
        id: joinColumnNames.client.project_id
        clients_id: joinColumnNames.client.id

    @clientsCrud.rootGETTransforms =
      query: validators.mapKeys auth_user_id: joinColumnNames.client.auth_user_id
      params: validators.mapKeys id: joinColumnNames.client.project_id

    @clients = @clientsCrud.root
    @clientsById = @clientsCrud.byId

    #                                          :notes_id"  :(id -> project_id)
    @notesCrud = routeCrud(@svc.notes, 'notes_id', 'NotesHasManyRouteCrud',['query','params'])
    ["byIdGETTransforms","rootGETTransforms"].forEach (transFormMethod) =>
      @notesCrud[transFormMethod] =
        query: validators.mapKeys {id: "#{usrTableNames.project}.id",notes_id: "#{usrTableNames.notes}.id"}
        params: validators.mapKeys id: "#{usrTableNames.notes}.project_id"
    @notes = @notesCrud.root
    @notesById = @notesCrud.byId

    #                                                     :drawn_shapes_id"  :(id -> project_id)
    @drawnShapesCrud = routeCrud(@svc.drawnShapes, 'drawn_shapes_id', 'DrawnShapesHasManyRouteCrud')
    ["byIdGETTransforms","rootGETTransforms"].forEach (transFormMethod) =>
      @drawnShapesCrud[transFormMethod] =
        query: validators.mapKeys {id: "#{usrTableNames.project}.id",drawn_shapes_id: "#{usrTableNames.drawnShapes}.id"}
        params: validators.mapKeys id: "#{usrTableNames.drawnShapes}.project_id"

    @drawnShapes = @drawnShapesCrud.root
    @drawnShapesById = @drawnShapesCrud.byId

    super arguments...

  byIdGET: (req, res, next) =>
    console.log req.query
    console.log req.params
    #so this is where bookshelf or objection.js would be much more concise
    super(req, res, next)
    .then (project) =>
      @clientsCrud.rootGET(req, res, next)
      .then (clients) ->
        project.clients = clients
        project
    .then (project) =>
      @notesCrud.rootGET(req, res, next)
      .then (notes) ->
        project.notes = notes
        project
    .then (project) =>
      @drawnShapesCrud.rootGET(req, res, next)
      .then (drawnShapes) ->
        project.drawnShapes = drawnShapes
        project


safeProjectCols = (require '../utils/util.sql.helpers').columns.project
module.exports = mergeHandles new ProjectRouteCrud(ProjectSvc, undefined, 'ProjectRouteCrud').init(true, safeProjectCols),
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
