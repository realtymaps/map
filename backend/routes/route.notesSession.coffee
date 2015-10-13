Promise = require 'bluebird'
logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
notesSvc = (require '../services/services.user').notes
{Crud, wrapRoutesTrait} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
_ = require 'lodash'
{crsFactory} = require '../../common/utils/enums/util.enums.map.coord_system'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user')
sqlHelpers = require '../utils/util.sql.helpers'

safeQuery = sqlHelpers.columns.notes

###
TODO: Add double security to make sure that users can not cross edit notes they do not own or do not have perms too
###
class NotesSessionCrud extends Crud
  @include userExtensions.route
  init: ->
    super()
    @safe = safeQuery
    @doLogQuery = true

  rootGET: (req, res, next) =>
    logger.debug "rootGet of notes"
    #since we have middleware that requires login going into this unless statement is a server error
    @toLeafletMarker @withUser req, =>
      logger.debug "rootGet has user"
      super(req, res, next)
    ,

  rootPOST: (req, res, next) =>
    @withUser req, req.body, =>
      if req.body?.geom_point_json?
        req.body.geom_point_json.crs = crsFactory()
      @svc.create(req.body, undefined, @doLogQuery, safeQuery)
      .catch _.partial(@onError, next)

  byIdGET: (req, res, next) =>
    @toLeafletMarker @withUser req, =>
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
