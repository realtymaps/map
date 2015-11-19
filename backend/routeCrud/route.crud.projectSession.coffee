userSvc = (require '../services/services.user').user.clone().init(false, true, 'singleRaw')
profileSvc = (require '../services/services.user').profile
notesSvc = (require '../services/services.user').notes
{Crud, wrapRoutesTrait, HasManyRouteCrud} = require '../utils/crud/util.crud.route.helpers'
_ = require 'lodash'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user.coffee')
userUtils = require '../utils/util.user'
sqlHelpers = require '../utils/util.sql.helpers'
logger =  require '../config/logger'

safeProject = sqlHelpers.columns.project
safeProfile = sqlHelpers.columns.profile
safeUser = sqlHelpers.columns.user
safeNotes = sqlHelpers.columns.notes

class ClientsCrud extends HasManyRouteCrud
  @include userExtensions.route
  init: () ->
    @restrictAll @withParent
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
    .then (clientId) ->
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

class ProjectsSessionCrud extends Crud
  @include userExtensions.route
  init: () ->
    @clientsCrud = new ClientsCrud(userSvc.clients, 'client_id', 'project_id', 'ClientsHasManyCrud').init(false)
    @clients = @clientsCrud.root
    @clientsById = @clientsCrud.byId

    @restrictAll @withUser
    super arguments...

  rootGET: (req, res, next) ->
    super req, res, next
    .then (projects) =>
      userSvc.clients.getAll parent_auth_user_id: req.user.id, project_id: _.pluck(projects, 'id'), @doLogQuery
      .then (clients) ->
        _.each projects, (project) ->
          project.clients = _.filter clients, project_id: project.id
        projects

  ###
    Remove or reset (sandbox) project data, including saved properties, notes, etc
  ###
  byIdDELETE: (req, res, next) ->
    @svc.getById req.params[@paramIdKey], @doLogQuery, req.query, safeProject

    .then (projects) =>
      project = projects[0]
      throw new Error 'Project not found' unless project?

      # If this is the users's sandbox -- just reset to default/empty state and remove associated notes
      if project.sandbox is true
        @svc.update project.id, properties_selected: {}, safeProject, @doLogQuery

        .then () ->
          profileSvc.getAll project_id: project.id, auth_user_id: req.user.id

        .then (profiles) =>
          profileReset =
            filters: {}
            map_results: {}
            map_position: {}

          profileSvc.update profiles[0].id, profileReset, safeProfile, @doLogQuery

        .then () =>
          notesSvc.delete {}, @doLogQuery, project_id: project.id, auth_user_id: req.user.id, safeNotes

        .then () ->
          delete req.session.profiles #to force profiles refresh in cache
          userUtils.cacheUserValues req

        .then () ->
          req.session.saveAsync()
          true

      # For non-sandbox projects, allow deletion
      else
        profileSvc.delete {}, @doLogQuery, project_id: project.id, auth_user_id: req.user.id, safeProfile
        .then () =>
          notesSvc.delete {}, @doLogQuery, project_id: project.id, auth_user_id: req.user.id, safeNotes
        .then () =>
          super req, res, next


ProjectsSessionRouteCrud = wrapRoutesTrait ProjectsSessionCrud

module.exports = ProjectsSessionRouteCrud
