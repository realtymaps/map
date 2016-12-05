auth = require '../utils/util.auth'
logger = require '../config/logger'
fipsCodes = require '../services/service.fipsCodes'
{RouteCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
{handleRoute} = require '../utils/util.route.helpers'
transforms = require '../utils/transforms/transforms.fipsCodes.coffee'
filterService = require '../services/service.properties.combined.filterSummary'


class FipsCodesCrud extends RouteCrud
  init:() ->
    @getAllTransforms = transforms.getAll

    @getAllMlsCodesTransforms = transforms.getAllMlsCodes

    super(true, ['state', 'count', 'code'])

  getAll: (req, res, next) =>
    handleRoute req, res, next, =>
      @validRequest req, 'getAll'
      .then (validReq) =>
        @svc.getAll(validReq.body)

  getAllMlsCodes: (req, res, next) =>
    handleRoute req, res, next, =>
      validateAndTransformRequest req, transforms.getAllMlsCodes
      .then (validReq) =>
        logger.debug "getAllMlsCodes"
        logger.debug validReq.body

        @svc.getAllMlsCodes(validReq.body)

  getAllSupportedMlsCodes: (req, res, next) =>
    handleRoute req, res, next, =>
      @validRequest req, 'getAllMlsCodes'
      .then (validReq) =>
        @svc.getAllSupportedMlsCodes(validReq.body)

  getForUser: (req, res, next) ->
    handleRoute req, res, next, ->
      filterService.getFipsMLSForUser(req.session.userid)
      .then ({fips}) ->
        fipsCodes.getByCode(fips)


module.exports = mergeHandles new FipsCodesCrud(fipsCodes),
  root:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_company','change_company','delete_company']}, logoutOnFail:true)
    ]
  # needs to be open for onboarding
  getAllMlsCodes:
    method: 'post'
  getAllSupportedMlsCodes:
    method: 'post'
  getForUser:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]    
