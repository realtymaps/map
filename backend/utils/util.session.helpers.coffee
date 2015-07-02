{currentProfile} = require '../../common/utils/util.profile'
logger = require '../config/logger'
module.exports =
  currentProfile: (session) ->
    currentProfile(session)
