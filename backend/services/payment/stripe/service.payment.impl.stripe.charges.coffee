{PartiallyHandledError, isUnhandled} = require '../../../utils/errors/util.error.partiallyHandledError'
{expectSingleRow} = require '../../../utils/util.sql.helpers'
tables = require '../../../config/tables'


StripeCharges = (stripe) ->
  getHistory = (auth_user_id) ->
    tables.auth.user()
    .select 'stripe_customer_id'
    .where id: auth_user_id
    .then (data) ->
      expectSingleRow(data)
    .then ({stripe_customer_id}) ->
      if !stripe_customer_id
        return []
      stripe.charges.list customer: stripe_customer_id
      .then (data) ->
        data
    .catch isUnhandled, (err) ->
      throw new PartiallyHandledError(err, "Problem encountered while retrieving payment history")


  getHistory: getHistory

module.exports = StripeCharges