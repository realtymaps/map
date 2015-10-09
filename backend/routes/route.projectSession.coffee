Promise = require 'bluebird'
logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
projectsSvc = (require '../services/services.user').project
{Crud, wrapRoutesTrait} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth.coffee'
_ = require 'lodash'

safeQuery = ['id', 'auth_user_id', 'archived', 'name', 'minPrice', 'maxPrice', 'beds', 'baths', 'sqft']

class ProjectsSessionCrud extends Crud
  init: ->
    super()
    @safe = safeQuery

  withUser: (req, target, cb) =>
    return @onError('User not logged in') unless req.user
    _.extend target, auth_user_id: req.user.id
    cb()

  rootGET: (req, res, next) =>
    @withUser req, req.query, =>
      super(req, res, next)

  rootPOST: (req, res, next) =>
    @withUser req, req.body, =>
      @svc.create(req.body, undefined, @doLogQuery, safeQuery)
      .catch _.partial(@onError, next)

  byIdGET: (req, res, next) =>
    @withUser req, req.query, =>
      @svc.getById(req.params[@paramIdKey], @doLogQuery, req.query, safeQuery)
      .catch _.partial(@onError, next)

  byIdPOST: (req, res, next) =>
    @withUser req, req.body, =>
      @svc.create(req.body, req.params[@paramIdKey], undefined, @doLogQuery, safeQuery)
      .catch _.partial(@onError, next)

  byIdDELETE: (req, res, next) =>
    @withUser req, req.query, =>
      @svc.delete(req.params[@paramIdKey], @doLogQuery, req.query, safeQuery)
      .catch _.partial(@onError, next)

  byIdPUT: (req, res, next) =>
    @withUser req, req.body, => super(req, res, next)

ProjectsSessionRouteCrud = wrapRoutesTrait ProjectsSessionCrud

module.exports = mergeHandles new ProjectsSessionRouteCrud(projectsSvc),
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
