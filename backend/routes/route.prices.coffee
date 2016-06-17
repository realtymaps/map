priceSvc = require '../services/service.prices'
auth = require '../utils/util.auth'
routeHelpers = require '../utils/util.route.helpers'


handles = routeHelpers.wrapHandleRoutes handles:
  mail: (req, res, next) ->
    priceSvc.getMailPrices()


module.exports = routeHelpers.mergeHandles handles,
  mail: method: "get"
