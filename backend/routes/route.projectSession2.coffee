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
sqlHelpers = require '../utils/util.sql.helpers'
userSvc = (require '../services/services.user').user.clone().init(false, true, 'singleRaw')
profileSvc = (require '../services/services.user').profile
clone = require 'clone'

safeProject = sqlHelpers.columns.project
safeProfile = sqlHelpers.columns.profile
safeUser = sqlHelpers.columns.user
safeNotes = sqlHelpers.columns.notes

class ClientsCrud extends RouteCrud
  init: () ->
    @svc.doLogQuery = true
    @reqTransforms =
      params: validators.reqId toKey: 'parent_auth_user_id'
    @byIdGETTransforms =
      query: validators.mapKeys
        id: joinColumnNames.client.project_id
        clients_id: joinColumnNames.client.id

    @rootGETTransforms =
      query: validators.mapKeys auth_user_id: joinColumnNames.client.auth_user_id
      params: [
          validators.mapKeys id: joinColumnNames.client.project_id
          validators.reqId toKey: 'parent_auth_user_id'
      ]

    super arguments...

  ###
    Create the user for this email if it doesn't alreayd exist, and then give them a profile for current project
    If a new user is created,
  ###
  rootPOST: (req, res, next) ->
    throw Error('User not logged in') unless req.user
    throw Error('Project ID required') unless req.params.id

    newUser =
      date_invited: new Date()
      parent_id: req.user.id
      username: req.body.username || "#{req.body.first_name}_#{req.body.last_name}".toLowerCase()

    userSvc.upsert  _.defaults(newUser, req.body), [ 'email' ], false, safeUser, @doLogQuery
    .then (clientIds) ->
      clientId = clientIds?[0]
      throw new Error 'user ID required - new or existing' unless clientId?

      newProfile =
        auth_user_id: clientId
        parent_auth_user_id: req.user.id
        project_id: req.params.id

      profileSvc.upsert newProfile, ['auth_user_id', 'project_id'], false, safeProfile, @doLogQuery

  ###
    Update user contact info - but only if the request came from the parent user
  ###
  byIdPUT: (req, res, next) ->
    @svc.getById req.params[@paramIdKey], @doLogQuery, parent_id: req.user.id, [ 'parent_id' ]
    .then (profile) =>
      throw new Error 'Client info cannot be modified' unless profile?
      userSvc.update profile.auth_user_id, req.body, safeUser, @doLogQuery

class ProjectRouteCrud extends RouteCrud
  @include userExtensions.route
  init: () ->
    #replaces the need for restrictAll7
    @reqTransforms =
      params: validators.reqId toKey: 'auth_user_id'
    @doLogQuery = ['query','params']

    @clientsCrud = new ClientsCrud(@svc.clients, 'clients_id', 'ClientsHasManyRouteCrud', ['query','params'])
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

  rootGET: (req, res, next) ->
    super req, res, next
    .then (projects) =>
      newReq = @cloneRequest(req)
      logger.debug "newReq: #{JSON.stringify newReq}"
      _.extend newReq.params, project_id: _.pluck(projects, 'id')
      @clientsCrud.rootGET(newReq,res,next)
      .then (clients) ->
        _.each projects, (project) ->
          project.clients = _.filter clients, project_id: project.id
        projects
    .then (projects) =>
      @notesCrud.rootGET(req, res, next)
      .then (notes) ->
        _.each projects, (project) ->
          project.notes = _.filter notes, project_id: project.id
        projects
    .then (projects) =>
      @drawnShapesCrud.rootGET(req, res, next)
      .then (drawnShapes) ->
        _.each projects, (project) ->
          projects.drawnShapes = _.filter drawnShapes, project_id: project.id
        projects

  byIdGET: (req, res, next) =>
    logger.debug @cloneRequest(req), true

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
