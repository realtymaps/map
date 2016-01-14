crudHelpers = require '../utils/crud/util.crud.route.helpers'
routeHelpers = require '../utils/util.route.helpers'
plansService = require '../services/service.plans'

class PlansCrud extends crudHelpers.RouteCrud
  rootGET: () =>
    @svc.getAll()

module.exports = routeHelpers.mergeHandles new PlansCrud(plansService),
  root: {}
