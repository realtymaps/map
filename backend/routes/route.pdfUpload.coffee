auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
pdfUploadService = require '../services/service.pdfUpload'
{validators} = require '../utils/util.validation'

reqTransforms =
  body:
    validators.reqId toKey: "auth_user_id"

class PdfUploadRoute extends RouteCrud

instance = new PdfUploadRoute pdfUploadService,
  debugNS: "pdfUploadRoute"
  reqTransforms: reqTransforms

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      # auth.requirePermissions({all:['add_','change_']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      # auth.requirePermissions({all:['add_','change_', 'delete_']}, logoutOnFail:true)
    ]
