_ = require 'lodash'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user.coffee')
{routeCrud, RouteCrud} = require '../utils/crud/util.crud.route.helpers'
EzRouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
logger = require('../config/logger').spawn('routes:crud:projectSession')
tables = require('../config/tables')
{joinColumnNames} = require '../utils/util.sql.columns'
{validators} = require '../utils/util.validation'
sqlHelpers = require '../utils/util.sql.helpers'
profileSvc = require '../services/service.profiles'
userSvc = (require '../services/services.user').user.clone().init(false, true, 'singleRaw')
userUtils = require '../utils/util.user'
ProjectSvcClass = require('../services/service.user.project')
# Needed for temporary create client user workaround until onboarding is completed
routeUserSessionInternals = require './route.userSession.internals'
Promise = require 'bluebird'
# End temporary
projectSvc = new ProjectSvcClass(tables.user.project).init(false)
safeUser = sqlHelpers.columns.user


class ClientsCrud extends RouteCrud
  init: () ->
    @svc.doLogQuery = true
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
  rootPOST: (req, res) ->
    throw new Error('User not logged in') unless req.user
    throw new Error('Project ID required') unless req.params.id
    clientEntryValue =
      user:
        date_invited: new Date()
        parent_id: req.user.id
        first_name: req.body.first_name
        last_name: req.body.last_name
        username: req.body.username || "#{req.body.first_name}_#{req.body.last_name}".toLowerCase()
        email: req.body.email
      parent:
        id: req.user.id
        first_name: req.user.first_name
        last_name: req.user.last_name
      project:
        id: req.params.id
        name: req.body.project_name
      evtdata:
        name: 'client_created' # altered to 'client_invited' for emails that exist in system
        verify_host: req.headers.host

    projectSvc.addClient clientEntryValue

  ###
    Update user contact info - but only if the request came from the parent user
  ###
  byIdPUT: (req, res) ->
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
      params: validators.mapKeys id: "#{tables.user.notes.tableName}.project_id"
      query: validators.object isEmptyProtect: true
      body: validators.object isEmptyProtect: true
    @notesCrud.byIdGETTransforms =
      params: validators.mapKeys {id: "#{tables.user.project.tableName}.id",notes_id: "#{tables.user.notes.tableName}.id"}
    @notes = @notesCrud.root
    @notesById = @notesCrud.byId

    bodyTransform =
      validators.object
        subValidateSeparate:
          geometry_center: validators.geojson(toCrs:true)
          geometry: validators.geojson(toCrs:true)
          geometry_line:  validators.geojson(toCrs:true)
          shape_extras: validators.object()
          area_name: validators.string()
          area_details: validators.string()

    #TODO: need to discuss on how auth_user_id is to be handled or if we need parent_auth_user_id as well?
    #                                                     :drawn_shapes_id"  :(id -> project_id)
    #@drawnShapesCrud = routeCrud(@svc.drawnShapes, 'drawn_shapes_id', 'DrawnShapesHasManyRouteCrud')
    class DrawnShapeCrud extends EzRouteCrud

      areas: (req, res, next) =>
        @getEntity(req, 'rootGET').then (entity) =>
          @_wrapRoute @svc.areas(entity), res

    @drawnShapesCrud = new DrawnShapeCrud @svc.drawnShapes,
      rootGETTransforms:
        params: validators.mapKeys id: "project_id"
        query: validators.object isEmptyProtect: true
        body: validators.object isEmptyProtect: true

      rootPOSTTransforms:
        params: validators.mapKeys id: "project_id"
        query: validators.object isEmptyProtect: true
        body: bodyTransform

      byIdGETTransforms:
        params: validators.mapKeys id: "project_id", drawn_shapes_id: 'id'

      byIdPUTTransforms:
        params: validators.mapKeys id: "project_id", drawn_shapes_id: 'id'
        query: validators.object isEmptyProtect: true
        body: bodyTransform

      byIdDELETETransforms:
        params: validators.mapKeys id: "project_id", drawn_shapes_id: 'id'
        query: validators.object isEmptyProtect: true

    @drawnShapes = @drawnShapesCrud.root
    @drawnShapesById = @drawnShapesCrud.byId

    super arguments...

  findProjectData: (projects, req, res, next) ->
    # setup an entity and filter for profileSvc call
    # `whereIn` means `req.params.id` could be a list of project_ids to pull from
    entity = auth_user_id: req.user.id
    entity.project_id = _.map(projects, 'id')  # sometimes list

    # pull project structures
    Promise.props
      clients: @clientsCrud.rootGET req, res, next
      notes: @notesCrud.rootGET req, res, next
      drawnShapes:
        @drawnShapesCrud.rootGET {req, res, next, lHandleQuery: false}
      profiles: profileSvc.getAllBulk(entity)
    .then (props) ->
      grouped = _.mapValues props, (recs) -> _.groupBy recs, 'project_id'
      _.each projects, (project) ->
        project.clients = grouped.clients[project.id] or []
        project.notes = grouped.notes[project.id] or []
        project.drawnShapes = grouped.drawnShapes[project.id] or []

        # update the favorites from the project profile structure
        project.favorites = _.merge {},
          _.pluck(grouped.profiles[project.id], 'favorites')...,
          _.pluck(project.clients, 'favorites')...
      projects

  rootGET: (req, res, next) ->
    super(req, res, next)
    .then (projects) =>
      newReq = @cloneRequest(req)
      #TODO: figure out how to do this as a transform (then cloneRequest will not be needed)
      _.extend newReq.params, id: _.pluck(projects, 'id') #set to id since it gets mapped to user_profile.project_id

      @findProjectData projects, newReq, res, next

  byIdGET: (req, res, next) =>
    #so this is where bookshelf or objection.js would be much more concise
    super(req, res, next)
    .then (project) ->
      if not project?
        # Look for viewer profile
        profileSvc.getAll "#{tables.user.profile.tableName}.auth_user_id": req.user.id, project_id: req.params.id
        .then sqlHelpers.singleRow
      else
        project
    .then (project) =>
      throw new Error('Project not found') unless project

      project.id = project.project_id ? project.id

      @findProjectData [project], req, res, next
      .then sqlHelpers.singleRow

  byIdDELETE: (req, res, next) ->
    super(req, res, next)
    .then () ->
      userUtils.cacheUserValues req, profiles: true # to force profiles refresh in cache
    .then () ->
      # Check if current profile was invalidated
      if not req.session.profiles[req.session.current_profile_id]?
        req.session.current_profile_id = _.find(req.session.profiles, 'sandbox', true)?.id
      req.session.saveAsync()
    .then () ->
      identity: userUtils.getIdentityFromRequest req


module.exports = ProjectRouteCrud
