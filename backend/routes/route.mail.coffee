auth = require '../utils/util.auth'
RouteCrud = require '../utils/crud/util.ezcrud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
mailCampaignService = require '../services/service.mail_campaigns'
{validators} = require '../utils/util.validation'


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

  getPdf: (req, res, next) =>
    @custom @svc.getPdf(req.user.id, req.params.id), res

instance = new MailCampaignRoute mailCampaignService,
  debugNS: "mailRoute"
  reqTransforms: reqTransforms
  enableUpsert: true

module.exports = routeHelpers.mergeHandles instance,
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireProjectEditor(methods: ['get', 'post'], projectIdParam: null)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requireProjectEditor(methods: ['post', 'put', 'delete'], projectIdParam: null)
    ]
  getReviewDetails:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getProperties:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getLetters:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  testLetter:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  getPdf:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
