geohash64 = require 'geohash64'
requestUtil = require '../../utils/util.http.request'
paramsToObject = requestUtil.query.params.toObject

module.exports =

  allAllowed: paramsToObject [ "name", "address", "city", "state", "zipcode", "apn",
    "soldwithin", "acres", "price", "type", "bounds", "polys"]

  addressAllowed: paramsToObject ["bounds"]

  apnsAllowed: paramsToObject ["apn", "bounds"]

  transforms: [
    {
      param: "bounds"
      transform: (boundsStr, next) ->
        errorRet = undefined
        [
          {check: _.isString boundsStr, msg: "bounds must be a string"}
          {check: boundsStr != String::EMPTY, msg: "bounds string must not be empty"}
        ].forEach (c) ->
          unless c.check
            if next?
              errorRet = next(status: status.BAD_REQUEST, message: c.msg)
            errorRet = []
    
        return errorRet if errorRet?
        geohash64.decode boundsStr, true
    }
  ]

