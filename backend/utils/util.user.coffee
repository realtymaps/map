Promise = require 'bluebird'
_ = require 'lodash'
logger = require('../config/logger').spawn('util:user')
config = require '../config/config'
profileSvc = require '../services/service.profiles'
permissionsService = require '../services/service.permissions'

safeUserFields = [
  'cell_phone'
  'email'
  'first_name'
  'id'
  'last_name'
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
  'stripe_plan_id'
  'mlses_verified'
  'fips_codes'
]

# tests subscription status of the (if active) req.session
# This is leveraged in middleware, but can be used in route code for business logic needs
isSubscriber = (req) ->
  return req?.session?.subscription? and req.session.subscription in config.SUBSCR.PLAN.PAID_LIST

# caches permission and group membership values on the user session; we could
# get into unexpected states if those values change during a session, so we
# cache them instead of refreshing.  This means for certain kinds of changes
# to a user account, we will either need to explicitly refresh these values,
# or we'll need to log out the user and let them get refreshed when they log
# back in.
cacheUserValues = (req, reload = {}) ->

  if !req.session.permissions or reload?.permissions
    logger.debug 'req.session.permissions'
    permissionsPromise = permissionsService.getPermissionsForUserId(req.user.id)
    .then (permissionsHash) ->
      logger.debug 'req.session.permissions.then'
      req.session.permissions = permissionsHash

  if !req.session.groups or reload?.groups
    logger.debug 'req.session.groups'
    groupsPromise = permissionsService.getGroupsForUserId(req.user.id)
    .then (groupsHash) ->
      logger.debug 'req.session.groups.then'
      req.session.groups = groupsHash


  if !req.session.profiles or reload?.profiles
    logger.debug "req.session.profiles: #{req.user.id}"

    # if user is subscriber, use service endpoint that includes sandbox creation and display
    if isSubscriber(req)
      profilesPromise = profileSvc.getProfiles req.user.id

    # user is a client, and unallowed to deal with sandboxes
    else
      profilesPromise = profileSvc.getClientProfiles req.user.id

    profilesPromise = profilesPromise
    .then (profiles) ->
      logger.debug 'profileSvc.getProfiles.then'
      req.session.profiles = profiles


  Promise.all([permissionsPromise, groupsPromise, profilesPromise])
  .catch (err) ->
    logger.error "error caching user values for user: #{req.user.email}"
    Promise.reject(err)

getIdentityFromRequest = (req) ->
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


module.exports = {
  cacheUserValues
  isSubscriber
  getIdentityFromRequest
  safeUserFields
}
