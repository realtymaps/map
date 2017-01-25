ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("service:notification:base")
# coffeelint: enable=check_scope
clone = require 'clone'


class NotifcationBaseService extends ServiceCrud

  id: () ->
    @dbFn.tableName + ".id"

  mapEntity: (entity) ->
    toMap = {
      frequency: "#{tables.user.notificationFrequencies.tableName}.code_name"
      method: "#{tables.user.notificationMethods.tableName}.code_name"
      id: @id()
    }
    cloned = clone(entity)
    for k, v of cloned
      do(k,v) ->
        if toMap[k]?
          cloned[toMap[k]] = v
          delete cloned[k]
    return cloned


module.exports = NotifcationBaseService
