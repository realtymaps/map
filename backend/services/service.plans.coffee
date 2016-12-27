memoize = require 'memoizee'
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'
logger = require('../config/logger').spawn("service:plans")

stripe = null
require('./services.payment').then (svc) -> stripe = svc.stripe


getAll = () ->
  stripe.plans.list()
  .then (results) ->
    plans = results.data
    logger.debug -> "Retrieved plan list:\n#{JSON.stringify(plans)}"
    plans
getAll = memoize(getAll, maxAge: 24*60*60*1000) # memoize for a day


getPlanById = (stripe_plan_id) ->
  stripe.plans.retrieve stripe_plan_id
  .then (plan) ->
    logger.debug -> "Retrieved plan:\n#{JSON.stringify(plan)}"
    plan
  .catch (err) ->
    throw new PartiallyHandledError(err, "Could not retrieve stripe plan id #{stripe_plan_id}")
getPlanById = memoize(getPlanById, maxAge: 24*60*60*1000) # memoize for a day

module.exports = {
  getAll
  getPlanById
}
