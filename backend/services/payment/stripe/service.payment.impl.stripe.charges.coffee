Promise = require 'bluebird'
tables = require '../../../config/tables'

StripeCharges = (stripe) ->
  #console.log "\n\nstripe:\n#{JSON.stringify(stripe,null,2)}"
  getHistory = (auth_user_id) ->
    Promise.try () ->
      console.log "auth_user_id:\n#{auth_user_id}"
      return [{one: 1},{two: 2}]
  getHistory: getHistory

module.exports = StripeCharges