keystore = require '../services/service.keystore'
crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
clone = require 'clone'
numeral = require 'numeral'

class PlansCrud extends crudHelpers.RouteCrud
  rootGET: () =>
    @svc.cache.getValuesMap('plans')
    .then (plans) ->
      for key, val of plans
        val.priceFormatted = '$' + numeral(val.price).format('0.00a')
        copy = clone val
        if copy.alias?
          copy.alias = key
          plans[val.alias] = copy
      plans

module.exports = routeHelpers.mergeHandles new PlansCrud(keystore),
  root: {}
