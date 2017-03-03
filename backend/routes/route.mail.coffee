auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
mailCampaignService = require '../services/service.mail_campaigns'
{validators} = require '../utils/util.validation'
lobService = require '../services/service.lob'
LobErrors = require '../utils/errors/util.errors.lob'
{QuietlyHandledError,isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
analyzeValue = require '../../common/utils/util.analyzeValue'


reqTransforms =
  body:
    validators.reqId toKey: "auth_user_id"

class MailCampaignRoute extends RouteCrud
  getReviewDetails: (req, res, next) =>
    @custom @svc.getReviewDetails(req.user.id, req.params.id, req.body), res

  getProperties: (req, res, next) =>
    @custom @svc.getProperties(req.params.project_id, req.user.id), res

  getLetters: (req, res, next) =>
    @custom @svc.getLetters(req.user.id), res

  testLetter: (req, res, next) =>
    @custom @svc.testLetter(req.params.letter_id, req.user.id), res

  sendCampaign: (req, res, next) =>
    @custom @svc.sendCampaign(req.user.id, req.params.id), res

  getLetterPreview: (req, res, next) ->
    type = req.params.type || 'medium'
    lobService.getLetterPreviewUrls(req.lobLetterId)
    .then (urls) ->
      if !urls[type]
        throw new QuietlyHandledError({returnStatus: 404}, "Requested letter not found, or preview type not available.")
      res.redirect(urls[type])
    .catch isCausedBy(LobErrors.LobNotFoundError), (err) ->
      throw new QuietlyHandledError({returnStatus: 404}, "Requested letter not found, or preview type not available.")


instance = new MailCampaignRoute mailCampaignService,
  debugNS: "mailRoute"
  reqTransforms: reqTransforms
  enableUpsert: true

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin()
      auth.requireProjectEditor(methods: ['get', 'post'], projectIdParam: null)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin()
      auth.requireProjectEditor(methods: ['post', 'put', 'delete'], projectIdParam: null)
    ]
  getReviewDetails:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
  getProperties:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
  getLetters:
    methods: ['get']
    middleware: [
      auth.requireLogin()
    ]
  testLetter:
    methods: ['post']
    middleware: [
      auth.requireLogin()
    ]
  sendCampaign:
    methods: ['post']
    middleware: [
      auth.requireLogin()
    ]
  getLetterPreview:
    methods: ['get']
    middleware: [
      auth.requireLetterProject()
    ]
