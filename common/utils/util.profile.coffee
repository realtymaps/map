{hiddenRequire} = require './webpackHack.coffee'
unless window?
  _ = hiddenRequire('lodash')

currentProfile = (obj, currentProfileStr = 'current_profile_id') ->
  # console.log obj
  # console.log obj.current_profile_id
  # console.log currentProfileStr
  # console.log obj[currentProfileStr]
  unless obj[currentProfileStr]
    throw "No Profile has been selected!"

  obj.profiles[obj[currentProfileStr]]

currentUiProfile = (identity) ->
  currentProfile(identity, 'currentProfileId')

module.exports =
  currentProfile: currentProfile
  currentUiProfile: currentUiProfile
  uiProfile: currentUiProfile
