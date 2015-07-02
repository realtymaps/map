Promise = require 'bluebird'

logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
userService = require '../services/service.user'
# userUtils = require '../utils/util.user'
ExpressResponse = require '../utils/util.expressResponse'
config = require '../config/config'
{methodExec} = require '../utils/util.route.helpers'
_ = require 'lodash'

mainSvc = userService

root = (req, res, next) ->
  methodExec req,
    GET: () ->
      mainSvc.getAll().stringify().pipe(res)

    POST: () -> #create
      mainSvc.create(req.body).stringify().pipe(res)

byId = (req, res, next) ->
  methodExec req,
    GET: () ->
      mainSvc.getById(req.params.id).stringify().pipe(res)
    POST: () ->
      mainSvc.create(req.body, req.params.id).stringify().pipe(res)
    DELETE: () ->
      mainSvc.delete(req.body, req.params.id).stringify().pipe(res)
    PUT: () ->
      mainSvc.update(req.params.id, req.body).stringify().pipe(res)

module.exports =
  root: root
  byId: byId
