config = require '../../config/config'
{validators} = require '../util.validation'

module.exports =

  updatePlan:
    params: validators.object subValidateSeparate:
      plan: validators.choice(choices: config.SUBSCR.PLAN.PAID_LIST)
    query: validators.object isEmptyProtect: true

  deactivation:
    params: validators.object isEmptyProtect: true
    query: validators.object isEmptyProtect: true
    body: validators.object subValidateSeparate:
      reason: validators.string()

  reactivation:
    params: validators.object isEmptyProtect: true
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
