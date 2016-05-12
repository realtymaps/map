clientEntrySvc = require '../services/service.clientEntry'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'

handles = wrapHandleRoutes handles:
  getClientEntry: (req) ->
    clientEntrySvc.getClientEntry req.query.key

module.exports = mergeHandles handles,
  getClientEntry: method: 'get'

