#logger = require('../config/logger').spawn("route.onboarding")
{validateAndTransformRequest} = require '../utils/util.validation'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')
{expectSingleRow} = require '../utils/util.sql.helpers'
dbs = require '../config/dbs'
internals = require './route.onboarding.internals'
notificationConfigService = require('../services/service.notification.config').instance

module.exports =
  createUser:
    method: "post"
    handleQuery: true
    handle: (req, res, next) ->
      validateAndTransformRequest req, onboardingTransforms.createUser
      .then (validReq) ->
        {plan, token, fips_code, mls_code, mls_id} = validReq.body
        plan = plan.name
        dbs.transaction 'main', (transaction) ->
          internals.createNewUser({body:validReq.body, transaction, plan})
          .then (authUser) ->
            expectSingleRow(authUser)
          .then (authUser) ->
            notificationConfigService.setNewUserDefaults({authUser, transaction})
          .then (authUser) ->
            internals.setMlsPermissions({authUser, fips_code, mls_code, mls_id, plan, transaction})
          .then (authUser) ->
            internals.submitPaymentPlan {plan, token, authUser, transaction}
          .then ({authUser, customer}) ->
            internals.submitEmail {authUser, plan, customer}
