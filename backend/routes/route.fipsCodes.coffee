auth = require '../utils/util.auth'
logger = require '../config/logger'
fipsCodes = require '../services/service.fipsCodes'
{RouteCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
{validators} = require '../utils/util.validation'
{handleRoute} = require '../utils/util.route.helpers'
_ = require 'lodash'

class FipsCodesCrud extends RouteCrud
  init:() ->
    @getAllTransforms =
      params: validators.object isEmptyProtect: true
      query: validators.object isEmptyProtect: true
      body: validators.object subValidateSeparate:
        state: validators.string(minLength:2, maxLength:2)

    @getAllMlsCodesTransforms =
      params: validators.object isEmptyProtect: true
      query: validators.object isEmptyProtect: true
      body: validators.object subValidateSeparate:
        state: validators.string(minLength:2)
        mls: validators.string(minLength:2)
        county: validators.string(minLength:2)
        fips_code: validators.string(minLength:4)
        id: validators.integer()

    super(true, ['state', 'count', 'code'])

  getAll: (req, res, next) =>
    handleRoute req, res, next, =>
      @validRequest req, 'getAll'
      .then (validReq) =>
        @svc.getAll(validReq.body)

  getAllMlsCodes: (req, res, next) =>
    handleRoute req, res, next, =>
      @validRequest req, 'getAllMlsCodes'
      .then (validReq) =>
        @svc.getAllMlsCodes(validReq.body)

  getAllSupportedMlsCodes: (req, res, next) =>
    handleRoute req, res, next, =>
      @validRequest req, 'getAllMlsCodes'
      .then (validReq) =>
        @svc.getAllSupportedMlsCodes(validReq.body)

module.exports = mergeHandles new FipsCodesCrud(fipsCodes),
  root:
    method: 'post'
  getAllMlsCodes:
    method: 'post'
  getAllSupportedMlsCodes:
    method: 'post'
