logger = require '../config/logger'
_ = require 'lodash'
status = require '../../common/utils/httpStatus'

cleanQuery = (query) ->
  _.each query, (value,key) ->
    query[key] = decodeURIComponent value

module.exports =
  query:
    params:
      cleanQuery: cleanQuery

      toObject: (params, paramsObj = {}) ->
        params.forEach (p)->
          paramsObj[p] = true
        paramsObj

      isAllowed: (query, qAllowedObj, fnName, allowed = false,badKeys = [])->
        fnName = if fnName then "#{fnName} ->" else ""
        query = _.clone query, true
        logger.log "debug", "#{fnName} query: %j", query, {}
        if _.keys(query).length
          allowed = _.all query, (value, key) ->
            unless qAllowedObj[key]
              badKeys.push key
              return false
            true
          # query = cleanQuery query
          allowed: allowed
          badKeys: badKeys

    #iterate through all params and transform / map each value back to the obj[param]
    transform: (obj, transforms, next) ->
      transforms.forEach (t) ->
        if obj[t.param]?
          obj[t.param] = t.transform(obj[t.param],next)
          logger.debug "transform: #{obj}"
      obj

    execute: (isAllowedObj, next, res, execFn)->
      allowed = isAllowedObj.allowed
      badKeys = isAllowedObj.badKeys

      if allowed
        return execFn()

      msg = if badKeys.length then "Query Params invalid! #{JSON.stringify badKeys}"
      else "Query Params empty!"

      next status:status.BAD_REQUEST, message: msg