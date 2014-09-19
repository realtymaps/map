logger = require '../../config/logger'
countySvc = do require '../../services/service.properties.county'
requestUtil = require '../utils/util.http.request'
memoize = require('../../extensions/memoizee').memoizeExp

paramsToObject = requestUtil.query.params.toObject
paramsAreAllowed = requestUtil.query.params.isAllowed
queryExec = requestUtil.query.execute

allAllowed = paramsToObject [ "name", "address", "city", "state", "zipcode", "apn",
  "soldwithin", "acres", "price", "type", "bounds", "polys"]

addressAllowed = paramsToObject ["bounds"]

apnsAllowed = paramsToObject ["apn", "bounds"]

###
  do validation later with express validation
  (for ints, strings etc add to util.http.request)
###
module.exports = () ->

  getAll: memoize (req, res, next) ->
    allowedObj = paramsAreAllowed req.query, allAllowed, "getAll"

    queryExec allowedObj, next, res,  ->
      countySvc.getAll(req.query, next).then (json) ->
        res.send json

  getAddresses: memoize (req, res, next) ->
    allowedObj = paramsAreAllowed req.query, addressAllowed, "getAddresses"

    queryExec allowedObj, next, res, ->
      countySvc.getAddresses(req.query, next).then (json) ->
        res.send json

  getApn: memoize (req, res, next) ->
    allowedObj = paramsAreAllowed req.query, apnsAllowed, "getApn"

    queryExec allowedObj, next, res,  ->
      countySvc.getByApn(req.query, next).then (json) ->
        res.send json
