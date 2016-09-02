logger = require '../config/logger'
notesSvc = require '../services/services.notes'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'
{validators} = require '../utils/util.validation'
routeHelpers = require '../utils/util.route.helpers'


bodyTransform =
  validators.object
    subValidateSeparate:
      geometry_center: validators.geojson(toCrs:true)
      text: validators.string(minLength: 1)
      title: validators.string()
      rm_property_id: validators.string()
      project_id: validators.integer()

###
TODO: SPECS to double check security for notes permissions to notes owners
TODO: Validate query and body params.
###
class NotesSessionCrud extends RouteCrud


# Yay for the new style
instance = new NotesSessionCrud notesSvc,
  debugNS: 'notesRoute'
  # as more parameters become necessary to filter on note model, we
  # can add elements to `query:` array below to clean & authenticate them
  rootPOSTTransforms:
    body: [
      bodyTransform
      validators.reqId()
    ]
  byIdPutTransforms:
    body: bodyTransform

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireProject({ methods:['get'], projectIdParam: 'project_id'})
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireProject({ methods:['get'], projectIdParam: 'project_id'})
      auth.requireProject({ methods:['put'], projectIdParam: 'body.project_id'})
      auth.requireProjectEditor({ methods: ['delete'], getProjectFromSession: true })
    ]
