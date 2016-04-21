logger = require '../config/logger'
notesSvc = (require '../services/services.user').notes
{Crud, wrapRoutesTrait} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
{validators} = require '../utils/util.validation'
userExtensions = require('../utils/crud/extensions/util.crud.extension.user')
{basicColumns} = require '../utils/util.sql.columns'


bodyTransform =
  validators.object
    subValidateSeparate:
      geom_point_json: validators.geojson(toCrs:true)
      text: validators.string(minLength: 1)
      title: validators.string()
      rm_property_id: validators.string()
      project_id: validators.integer()

###
TODO: SPECS to double check security for notes permissions to notes owners
TODO: Validate query and body params.
###
class NotesSessionCrud extends Crud
  @include userExtensions.route
  init: () ->
    @reqTransforms =
      params: validators.reqId()
      query: validators.object isEmptyProtect: true

    @rootPOSTTransforms =
      body: [
        bodyTransform
        validators.reqId()
      ]

    @byIdPutTransforms =
      body: bodyTransform

    super(arguments...)

  rootGET: (req, res, next) =>
    super(req, res, next)
    .then (notes) =>
      @toLeafletMarker notes



NotesSessionRouteCrud = wrapRoutesTrait NotesSessionCrud

module.exports = mergeHandles new NotesSessionRouteCrud(notesSvc).init(true, basicColumns.notes),
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
