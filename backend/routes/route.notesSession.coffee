Promise = require 'bluebird'
logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
notesSvc = (require '../services/services.user').notes
{Crud, wrapRoutesTrait} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth.coffee'
_ = require 'lodash'
{crsFactory} = require '../../common/utils/enums/util.enums.map.coord_system'

safeQuery = ['id', 'auth_user_id', 'text', 'geom_point_json', 'title', 'project_id', 'rm_property_id']

###
TODO: Add double security to make sure that users can not cross edit notes they do not own or do not have perms too
###
class NotesSessionCrud extends Crud
  init: ->
    super()
    @safe = safeQuery

  withUser: (req, toExtend, cb) =>
    return @onError('User not logged in') unless req.user
    unless toExtend
      toExtend = req.query or {}
    cb = toExtend if _.isFunction toExtend

    _.extend toExtend, auth_user_id: req.user.id
    cb(toExtend)

  rootGET: (req, res, next) =>
    logger.debug "rootGet of notes"
    #since we have middleware that requires login going into this unless statement is a server error
    @withUser req, =>
      logger.debug "rootGet has user"
      super(req, res, next)

  rootPOST: (req, res, next) =>
    @doLogQuery = true
    @withUser req, req.body, =>
      if req.body?.geom_point_json?
        req.body.geom_point_json.crs = crsFactory()
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
    @withUser req, (restrict) =>
      @svc.delete(req.params[@paramIdKey], @doLogQuery, restrict, safeQuery)
      .catch _.partial(@onError, next)

  byIdPUT: (req, res, next) =>
    @doLogQuery = true
    @withUser req, req.body, =>
      if req.body?.geom_point_json?
        req.body.geom_point_json.crs = crsFactory()
      super(req, res, next)

NotesSessionRouteCrud = wrapRoutesTrait NotesSessionCrud

module.exports = mergeHandles new NotesSessionRouteCrud(notesSvc),
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
