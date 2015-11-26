_ = require 'lodash'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user.coffee')
{routeCrud, RouteCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'
usrTableNames = require('../config/tableNames').user
{joinColumnNames} = require '../utils/util.sql.columns'
{validators} = require '../utils/util.validation'
sqlHelpers = require '../utils/util.sql.helpers'
userSvc = (require '../services/services.user').user.clone().init(false, true, 'singleRaw')
profileSvc = (require '../services/services.user').profile
userUtils = require '../utils/util.user'

# Needed for temporary create client user workaround until onboarding is completed
userSessionSvc = require '../services/service.userSession'
permissionsService = require '../services/service.permissions'
# End temporary

safeProfile = sqlHelpers.columns.profile
safeUser = sqlHelpers.columns.user

class ClientsCrud extends RouteCrud
  init: () ->
    @svc.doLogQuery = true
    @reqTransforms = params: validators.reqId toKey: 'parent_auth_user_id'
    @byIdGETTransforms =
      params: validators.mapKeys
        id: joinColumnNames.client.project_id
        clients_id: joinColumnNames.client.id
      query: validators.object isEmptyProtect: true
      body: validators.object isEmptyProtect: true

    @byIdDELETETransforms =
      params: validators.mapKeys
        id: joinColumnNames.client.project_id
        clients_id: joinColumnNames.client.id
      query: validators.object isEmptyProtect: true
      body: validators.object isEmptyProtect: true

    @rootGETTransforms =
      params: validators.mapKeys
        id: joinColumnNames.client.project_id
        auth_user_id: joinColumnNames.client.auth_user_id
      query: validators.object isEmptyProtect: true
      body: validators.object isEmptyProtect: true

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
    #TODO: the majority of this is service business logic and should be moved to service.user.project
    userSvc.upsert  _.defaults(newUser, req.body), [ 'email' ], false, safeUser, @doLogQuery
    .then (clientId) ->
      throw new Error 'user ID required - new or existing' unless clientId?

      # TODO - TEMPORARY WORKAROUND for new client users until onboarding is complete.  Should be removed at that time
      newUser.id = clientId
      userSessionSvc.updatePassword newUser, 'Password$1'

    .then ->
      # TODO - TEMPORARY WORKAROUND - Look up permission ID from DB
      permissionsService.getPermissionForCodename 'unlimited_logins'

    .then (authPermission) ->
      logger.debug "Found new client permission id: #{authPermission.id}"

      # TODO - TEMPORARY WORKAROUND to add unlimited access permission to client user, until onboarding is completed
      throw new Error 'Could not find permission id for "unlimited_logins"' unless authPermission

      permission =
        user_id: newUser.id
        permission_id: authPermission.id

      userSvc.permissions.create permission, null, ['user_id', 'permission_id'], @doLogQuery

    .then ->
      newProfile =
        auth_user_id: newUser.id
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
      #TODO: the majority of this is service business logic and should be moved to service.user.project
      userSvc.update profile.auth_user_id, req.body, safeUser, @doLogQuery

class ProjectRouteCrud extends RouteCrud
  @include userExtensions.route
  init: () ->
    #replaces the need for restrictAll
    @reqTransforms =
      params: validators.reqId toKey: 'auth_user_id'

    @clientsCrud = new ClientsCrud(@svc.clients, 'clients_id', 'ClientsHasManyRouteCrud', ['query','params'])
    @clients = @clientsCrud.root
    @clientsById = @clientsCrud.byId

    #                                          :notes_id"  :(id -> project_id)
    @notesCrud = routeCrud(@svc.notes, 'notes_id', 'NotesHasManyRouteCrud',['query','params'])
    @notesCrud.rootGETTransforms =
      params: validators.mapKeys id: "#{usrTableNames.notes}.project_id"
      query: validators.object isEmptyProtect: true
      body: validators.object isEmptyProtect: true
    @notesCrud.byIdGETTransforms =
      params: validators.mapKeys {id: "#{usrTableNames.project}.id",notes_id: "#{usrTableNames.notes}.id"}
    @notes = @notesCrud.root
    @notesById = @notesCrud.byId

    #TODO: need to discuss on how auth_user_id is to be handled or if we need parent_auth_user_id as well?
    #                                                     :drawn_shapes_id"  :(id -> project_id)
    @drawnShapesCrud = routeCrud(@svc.drawnShapes, 'drawn_shapes_id', 'DrawnShapesHasManyRouteCrud')
    @drawnShapesCrud.doLogRequest = ['params', 'body`']
    @drawnShapesCrud.rootGETTransforms =
      params: validators.mapKeys id: "#{usrTableNames.drawnShapes}.project_id"
      query: validators.object isEmptyProtect: true
      body: validators.object isEmptyProtect: true
    @drawnShapesCrud.byIdGETTransforms =
      params: validators.mapKeys {id: "#{usrTableNames.project}.id",drawn_shapes_id: "#{usrTableNames.drawnShapes}.id"}

    bodyTransform =
      validators.object
        subValidateSeparate:
          geom_point_json: validators.geojson(toCrs:true)
          geom_polys_json: validators.geojson(toCrs:true)
          geom_line_json:  validators.geojson(toCrs:true)

    @drawnShapesCrud.rootPOSTTransforms =
      params: validators.mapKeys id: "#{usrTableNames.project}.id"
      query: validators.object isEmptyProtect: true
      body: bodyTransform

    for route in ['byIdPUT', 'byIdDELETE']
      do (route) =>
        @drawnShapesCrud[route + 'Transforms'] =
          params: validators.mapKeys id: "#{usrTableNames.drawnShapes}.project_id", drawn_shapes_id: 'id'
          query: validators.object isEmptyProtect: true
          body: bodyTransform

    @drawnShapes = @drawnShapesCrud.root
    @drawnShapesById = @drawnShapesCrud.byId

    super arguments...

  rootGET: (req, res, next) ->
    super req, res, next
    .then (projects) =>
      newReq = @cloneRequest(req)
      logger.debug "newReq: #{JSON.stringify newReq}"
      #TODO: figure out how to do this as a transform (then cloneRequest will not be needed)
      _.extend newReq.params, id: _.pluck(projects, 'id')#set to id since it gets mapped to user_profile.project_id
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
          project.drawnShapes = _.filter drawnShapes, project_id: project.id
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

  byIdDELETE: (req, res, next) ->
    super req, res, next
    .then (isSandBox) ->
      if isSandBox
        if req?.session?.profiles
          delete req.session.profiles #to force profiles refresh in cache
        userUtils.cacheUserValues req
      isSandBox
    .then (isSandBox) ->
      req.session.saveAsync()
      true

module.exports = ProjectRouteCrud
