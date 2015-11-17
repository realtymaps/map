validLocalStore = require './util.validation.localStore'
logger = require '../../config/logger'
# GOAL: To get a key req.user.id from local store
# example:
# options:
#   clsKey: 'req.user.id'
#   toKey: 'auth_user_id'
#
# Post transform:
#
# New Object:
#
# auth_user_id: SOME_ID
#
# Returns the mapped object.
module.exports = (options = {}) ->
  clsKey = options.clsKey ? 'req.user.id'
  toKey = options.toKey ? 'auth_user_id'
  validLocalStore({clsKey, toKey})
