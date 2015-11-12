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
TODO: SPECS to double check security for notes permissions to notes owners
TODO: Validate query and body params.
###
class NotesSessionCrud extends Crud
  @include userExtensions.route
  init: () ->
    @restrictAll(@withUser())
    super()

  rootGET: (req, res, next) =>
    super(req, res, next)
    .then (notes) =>
      @toLeafletMarker notes

  rootPOST: (req, res, next) =>
    if req.body?.geom_point_json?
      req.body.geom_point_json.crs = crsFactory()
    super(req, res, next)

  byIdPUT: (req, res, next) ->
    if req.body?.geom_point_json?
      req.body.geom_point_json.crs = crsFactory()
    super(req, res, next)

NotesSessionRouteCrud = wrapRoutesTrait NotesSessionCrud

module.exports = mergeHandles new NotesSessionRouteCrud(notesSvc).init(true, safeQuery),
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
