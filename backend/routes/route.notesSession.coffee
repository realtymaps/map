logger = require '../config/logger'
notesSvc = require '../services/services.notes'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
auth = require '../utils/util.auth'
{validators} = require '../utils/util.validation'
routeHelpers = require '../utils/util.route.helpers'


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
class NotesSessionCrud extends RouteCrud


# Yay for the new style
instance = new NotesSessionCrud notesSvc,
  debugNS: 'notesRoute'
  reqTransforms:
    params: validators.reqId()
    query: validators.object isEmptyProtect: true
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
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
