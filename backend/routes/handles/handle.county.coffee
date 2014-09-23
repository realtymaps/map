logger = require '../../config/logger'
countySvc = do require '../../services/service.properties.county'
requestUtil = require '../utils/util.http.request'
memoize = require('../../extensions/memoizee').memoizeExp
geohash64 = require 'geohash64'

paramsToObject = requestUtil.query.params.toObject
paramsAreAllowed = requestUtil.query.params.isAllowed
exec = requestUtil.query.execute
transform = requestUtil.query.transform

allAllowed = paramsToObject [ "name", "address", "city", "state", "zipcode", "apn",
  "soldwithin", "acres", "price", "type", "bounds", "polys"]

addressAllowed = paramsToObject ["bounds"]

apnsAllowed = paramsToObject ["apn", "bounds"]


transforms = [
  param:"bounds"
  transform: (boundsStr, next) ->
    errorRet = undefined
    checks = [
      {check: _.isString boundsStr, msg: "bounds must be a string"}
      {check: boundsStr != String::EMPTY, msg: "bounds string must not be empty"}
    ].forEach (c) ->
      unless c.check
        if next?
          errorRet = next(status:status.BAD_REQUEST, message: c.msg)
        errorRet =  []

    return errorRet if errorRet?
    geohash64.decode boundsStr, true
]

###
  do validation later with express validation
  (for ints, strings etc add to util.http.request)
###
module.exports = () ->

  getAll: memoize (req, res, next) ->
    #are all query params allowed
    allowedObj = paramsAreAllowed req.query, allAllowed, "getAll"
    #convert what we need to
    transform req.query, transforms, next
    logger.debug req.query

    exec allowedObj, next, res,  ->
      countySvc.getAll(req.query, next).then (json) ->
        res.send json

  #if you want to get bounds via put or post , then you can send bounds as an array
