config = require '../config/config'
_ = require 'lodash'

dimensionLimits = config.IMAGES.dimensions.profile

safeUserFields = [
  'cell_phone'
  'email'
  'first_name'
  'id'
  'last_name'
  'username'
  'work_phone'
  'account_image_id'
  'address_1'
  'address_2'
  'us_state_id'
  'zip'
  'city'
  'website_url'
  'account_use_type_id'
  'company_id'
  'parent_id'
]

#main entry point to update root user info
safeRootFields = safeUserFields.concat([])

['company_id'].forEach ->
  safeRootFields.pop()

safeRootCompanyFields = [
  'address_1'
  'address_2'
  'zip'
  'name'
  'us_state_id'
  'phone'
  'fax'
  'website_url'
]

getIdentity = (req) ->
  if req.user
    # here we should probaby return some things from the user's profile as well, such as name
    user: _.pick req.user, safeUserFields
    subscription: req.session.subscription
    permissions: req.session.permissions
    groups: req.session.groups
    environment: config.ENV
    profiles: req.session.profiles
    currentProfileId: req.session.current_profile_id
  else
    null


module.exports ={
  dimensionLimits
  safeUserFields
  safeRootFields
  safeRootCompanyFields
  getIdentity
}
