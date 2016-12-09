logger = require('../config/logger').spawn("route.onboarding")
{validateAndTransformRequest} = require '../utils/util.validation'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')
{expectSingleRow} = require '../utils/util.sql.helpers'
dbs = require '../config/dbs'
internals = require './route.onboarding.internals'
httpStatus = require '../../common/utils/httpStatus'
{isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
{MlsAgentNotVierified} = require '../utils/errors/util.errors.onboarding'
ExpressResponse = require '../utils/util.expressResponse'

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
            throw new MlsAgentNotVierified("Agent not verified for mls_id: #{mls_id}, mls_code: #{mls_code} for email: #{validReq.body.email}")
            expectSingleRow(authUser)
          .then (authUser) ->
            internals.setMlsPermissions({authUser, fips_code, mls_code, mls_id, plan, transaction})
          .then (authUser) ->
            internals.submitPaymentPlan {plan, token, authUser, transaction}
          .then ({authUser, customer}) ->
            internals.submitEmail {authUser, plan, customer}

          .catch isCausedBy(MlsAgentNotVierified), (err) ->
            next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.UNAUTHORIZED, quiet: err.quiet})
          .catch (err) ->
            next new ExpressResponse(alert: {msg: "Oops, something went wrong. Please try again later"}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})
