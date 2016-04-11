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
      stripe.charges.list customer: stripe_customer_id
      .then (data) ->
        data

  getHistory: getHistory

module.exports = StripeCharges