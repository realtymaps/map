auth = require '../utils/util.auth'
logger = require('../config/logger').spawn('route:pdfUpload')
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
pdfUploadService = require '../services/service.pdfUpload'
{validators} = require '../utils/util.validation'

reqTransforms =
  body:
    validators.reqId toKey: "auth_user_id"

class PdfUploadRoute extends RouteCrud
  getSignedUrl: (req, res, next) =>
    @custom @svc.getSignedUrl(req.params.aws_key), res

  validatePdf: (req, res, next) =>
    test = @svc.validatePdf(req.params.aws_key)
    .then (result) ->
      if !result.isValid
        logger.warn "PDF Upload invalid from source: #{req.params.aws_key}, user: #{req.session.userid}, profile: #{req.session.current_profile_id}"
      result
    @custom test, res


instance = new PdfUploadRoute pdfUploadService,
  debugNS: "pdfUploadRoute"
  reqTransforms: reqTransforms

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
      # auth.requirePermissions({all:['add_','change_']})
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
      # auth.requirePermissions({all:['add_','change_', 'delete_']})
    ]
  getSignedUrl:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
  validatePdf:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
