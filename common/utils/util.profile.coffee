currentProfile = (obj, currentProfileStr = 'current_profile_id') ->
  unless obj[currentProfileStr]
    throw new Error('No Profile has been selected!')
  obj.profiles[obj[currentProfileStr]]

uiProfile = (identity) ->
  currentProfile(identity, 'currentProfileId')

module.exports = {
  currentProfile
  uiProfile
}
