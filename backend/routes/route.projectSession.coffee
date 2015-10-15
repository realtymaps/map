Promise = require 'bluebird'
logger = require '../config/logger'
userSvc = (require '../services/services.user').user
projectSvc = (require '../services/services.user').project
{Crud, wrapRoutesTrait, HasManyRouteCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth.coffee'
_ = require 'lodash'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user.coffee')
tables = require '../config/tables'
analyzeValue = require '../../common/utils/util.analyzeValue'

safeProject = ['id', 'auth_user_id', 'archived', 'name', 'minPrice', 'maxPrice', 'beds', 'baths', 'sqft']
safeProfile = ['id', 'auth_user_id', 'parent_auth_user_id', 'project_id', 'name', 'filters', 'properties_selected', 'map_toggles', 'map_position', 'map_results']
safeUser = ['username', 'password', 'first_name', 'last_name', 'email', 'cell_phone', 'work_phone', 'address_1', 'address_2', 'zip', 'city']

class ClientsCrud extends HasManyRouteCrud
  @include userExtensions.route
  init: () ->
    @restrictAll(@withParent)
    super()

  rootPOST: (req, res, next) ->
    throw Error('User not logged in') unless req.user
    throw Error('Project ID required') unless req.params.id

    Promise.try () ->
      userSvc.getAll email: req.body.email
    .then (maybeUser) ->
      if maybeUser?[0]
        maybeUser[0].id
      else
        tables.auth.user()
        .returning('id')
        .insert(_.pick(req.body, safeUser), defaultUser)
        .then (inserted) ->
          inserted?[0]

    .then (userId) =>
      newProfile =
        auth_user_id: userId
        parent_auth_user_id: req.user.id
        project_id: req.params.id

      @svc.create(newProfile, undefined, @doLogQuery)
    .catch _.partial(@onError, next)

class ProjectsSessionCrud extends Crud
  @include userExtensions.route
  init: () ->
    @clientsCrud = new ClientsCrud(userSvc.clients, 'client_id', 'project_id')
    @clients = @clientsCrud.root
    @clientsById = @clientsCrud.byId

    @restrictAll(@withUser)
    super()

ProjectsSessionRouteCrud = wrapRoutesTrait ProjectsSessionCrud

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
    methods: ['get', 'post', 'put'] # cannot be deleted
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]

