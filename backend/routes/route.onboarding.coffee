{validateAndTransformRequest} = require '../utils/util.validation'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')
internals = require './route.onboarding.internals'
dbs = require '../config/dbs'
{expectSingleRow} = require '../utils/util.sql.helpers'
notificationConfigService = require('../services/service.notification.config').instance


module.exports =

  createUser:
    method: "post"
    handleQuery: true
    handle: (req, res, next) ->
      validateAndTransformRequest req, onboardingTransforms.createUser
      .then ({body} = {}) ->
        {plan, token, fips_code, mls_code, mls_id, stripe_coupon_id} = body
        plan = plan.name
        dbs.transaction 'main', (transaction) ->
          internals.createNewUser({body, transaction, plan})
          .then (authUser) ->
            expectSingleRow(authUser)
          .then (authUser) ->
            notificationConfigService.setNewUserDefaults({authUser, transaction})
          .then (authUser) ->
            internals.setMlsPermissions({authUser, fips_code, mls_code, mls_id, plan, transaction})
          .then (authUser) ->
            internals.submitPaymentPlan {plan, token, authUser, transaction, stripe_coupon_id}
          .then ({authUser}) ->
            internals.submitEmail {authUser, plan}
