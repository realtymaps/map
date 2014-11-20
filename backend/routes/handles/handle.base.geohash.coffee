logger = require '../../config/logger'
requestUtil = require '../../utils/util.http.request'
paramsToObject = requestUtil.query.params.toObject
memoize = require('../../extensions/memoizee').memoizeExp
geohash64 = require 'geohash64'

paramsToObject = requestUtil.query.params.toObject
paramsAreAllowed = requestUtil.query.params.isAllowed
exec = requestUtil.query.execute
transform = requestUtil.query.transform

validation = require '../../utils/validation/util.validation.geohash'

validateHandle = (service, fnName) ->
  memoize (req, res, next) ->
    #are all query params allowed
    allowedObj = paramsAreAllowed req.query, validation.allAllowed, fnName
    #convert what we need to
    transform req.query, validation.transforms, next
    logger.debug req.query

    exec allowedObj, next, res, ->
      service[fnName](req.query, next).then (json) ->
        res.send json

validWrapService = (service, thing) ->
  _.keys(service).forEach (fnName) ->
    thing[fnName] = validateHandle service, fnName
  thing

###
  do validation later with express validation
  (for ints, strings etc add to util.http.request)
###
module.exports = (serviceUri, fnName = 'getAll') ->
  service = do require serviceUri
  _.extend @, validWrapService service, @
  @