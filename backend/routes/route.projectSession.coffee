Promise = require 'bluebird'
logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
projectsSvc = (require '../services/services.user').project
{Crud, wrapRoutesTrait} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth.coffee'
_ = require 'lodash'

safeQuery = ['id']

class ProjectsSessionCrud extends Crud
  init: ->
    super()
    @safe = safeQuery

  withUser: (req, cb) =>
    return @onError('User not logged in') unless req.user
    _.extend req.query, auth_user_id: req.user.id
    cb()

  rootGET: (req, res, next) =>
    logger.debug "rootGet of projects"
    @withUser req, =>
      logger.debug "rootGet has user"
      super(req, res, next)

  rootPOST: (req, res, next) =>
    @withUser req, =>
      @svc.create(req.body, undefined, @doLogQuery, safeQuery)
      .catch _.partial(@onError, next)

  byIdGET: (req, res, next) =>
    @withUser req, =>
      @svc.getById(req.params[@paramIdKey], @doLogQuery, req.query, safeQuery)
      .catch _.partial(@onError, next)

  byIdPOST: (req, res, next) =>
    @withUser req, =>
      @svc.create(req.body, req.params[@paramIdKey], undefined, @doLogQuery, safeQuery)
      .catch _.partial(@onError, next)

  byIdDELETE: (req, res, next) =>
    @withUser req, =>
      @svc.delete(req.params[@paramIdKey], @doLogQuery, req.query, safeQuery)
      .catch _.partial(@onError, next)

  byIdPUT: (req, res, next) =>
    @withUser req, => super(req, res, next)

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
