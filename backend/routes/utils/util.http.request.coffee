logger = require '../../config/logger'
_ = require 'lodash'
status = require '../../../common/utils/httpStatus'

module.exports =
  query:
    params:
      toObject: (params, paramsObj = {}) ->
        params.forEach (p)->
          paramsObj[p] = true
        paramsObj

      isAllowed: (query, qAllowedObj, allowed = false,badKeys = [])->
        query = _.clone query, true
        logger.log "debug", "query: %j", query, {}
        if _.keys(query).length
          allowed = _.all query, (value, key) ->
            unless qAllowedObj[key]
              badKeys.push key
              return false
            true
          allowed: allowed
          badKeys: badKeys

    execute: (isAllowedObj, next, res, execFn)->
      allowed = isAllowedObj.allowed
      badKeys = isAllowedObj.badKeys

      if allowed
        return execFn()

      msg = if badKeys.length then "Query Params invalid! #{JSON.stringify badKeys}"
      else "Query Params empty!"

      next status:status.BAD_REQUEST, message: msg
