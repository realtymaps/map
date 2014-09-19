logger = require '../../config/logger'
countySvc = do require '../../services/service.properties.county'
requestUtil = require '../utils/util.http.request'
memoize = require('../../extensions/memoizee').memoizeExp

paramsToObject = requestUtil.query.params.toObject
paramsAreAllowed = requestUtil.query.params.isAllowed
queryExec = requestUtil.query.execute

allAllowed = paramsToObject [ "name", "address", "city", "state", "zipcode", "apn",
  "soldwithin", "acres", "price", "type", "bounds", "polys"
]

addressAllowed = ["bounds"]


#do validation later with express validation
module.exports = () ->

  getAll: memoize (req, res, next) ->
    allowedObj = paramsAreAllowed req.query, allAllowed

    queryExec allowedObj, next, res,  ->
      countySvc.getAll(req.query, next).then (json) ->
        res.send json

  getAddresses: memoize (req, res, next) ->
    allowedObj = paramsAreAllowed req.query, addressAllowed

    queryExec allowedObj, next, res,  ->
      countySvc.getAddresses(req.query, next).then (json) ->
        res.send json

  getApn: memoize (req, res, next) ->
    list = req.path.split("/")
    list.forEach (item) ->
      switch item
        when "apn"
          obj[item] = decodeURIComponent(list.shift().replace(/\+/g, " "))
        when "bounds"
          obj[item] = decodeURIComponent(list.shift()).split(",")

    countySvc.getByApn(obj,next).then (json) ->
      res.send json
