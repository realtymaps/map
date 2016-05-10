Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
keystore = require '../services/service.keystore'
{singleRow} = require '../utils/util.sql.helpers'
profileSvc = require './service.profiles'
accountImagesSvc = require('./services.user').accountImages
tables = require '../config/tables'
config = require '../config/config'
userSessionErrors = require '../utils/errors/util.errors.userSession'

_getUser = (attributes) ->
  tables.auth.user()
  .where(attributes)
  .then (user=[]) ->
    user[0] ? {}

_updateUser = (id, attributes) ->
  tables.auth.user()
  .where(id: id)
  .update(attributes)

# this skeleton for handling password hashes will make it easier to migrate
# hashes to a new algo if we ever need to
preprocessHash = (password) -> Promise.try () ->
  if password?.indexOf('bcrypt$') == 0
    keystore.cache.getValue('password', namespace: 'hashing cost factors')
    .then (passwordCostFactor) ->
      hash = password.slice('bcrypt$'.length)
      update = (bcrypt.getRounds(hash) != passwordCostFactor)
      return {algo: 'bcrypt', hash: hash, needsUpdate: update}
  # ... else check for other valid formats and do preprocessing for them
  # ...
  # if nothing worked, indicate failure
  else
    Promise.reject('failed to determine password hash algorithm')

createPasswordHash = (password) ->
  keystore.cache.getValue('password', namespace: 'hashing cost factors')
  .then (passwordCostFactor) ->
    #logger.debug "creating bcrypt password hash with 2^#{cost} rounds"
    return bcrypt.hashAsync(password, passwordCostFactor)
  .then (hash) -> return "bcrypt$#{hash}"


verifyPassword = (email, password) ->
  #logger.debug "attempting to verify password for email: #{email}"
  _getUser(email: email)
  .then (user) ->
    if not user or not user?.password
      # best practice is to go ahead and hash the password before returning,
      # to prevent timing attacks from determining validity of email
      return createPasswordHash(password).then (hash) -> return false
    preprocessHash(user.password)
    .catch (err) ->
      logger.error "error while preprocessing password hash for email #{email}: #{err}"
      Promise.reject(err)
    .then (hashData) ->
      compare = Promise.resolve(false)
      switch hashData.algo
        when 'bcrypt'
          compare = bcrypt.compareAsync(password, hashData.hash)
      compare.then (match) ->
        if not match
          return Promise.reject("given password doesn't match hash for email: #{email}")
        #logger.debug "password verified for email: #{email}"
        if hashData.needsUpdate
          # in the background, update this user's hash
          logger.info "updating password hash for email: #{email}"
          createPasswordHash(password)
          .then (hash) -> _updateUser(user.id, password: hash)
          .catch (err) -> logger.error "failed to update password hash for userid #{user.id}: #{err}"
        return user


getImage = (entity) -> Promise.try () ->
  if !entity?.account_image_id?
    return null
  accountImagesSvc.getById(entity.account_image_id)
  .then singleRow

upsertImage = (entity, blob, tableFn = tables.auth.user) ->
  getImage(entity)
  .then (image) ->
    if image
      #update
      logger.debug "updating image for account_image_id: #{entity.account_image_id}"
      return accountImagesSvc.update(entity.account_image_id, blob:blob)
    #create
    logger.debug 'creating image'
    accountImagesSvc.create(blob:blob)
    .returning('id')
    .then singleRow
    .then (id) ->
      logger.debug "saving account_image_id: #{id}"
      tableFn().update(account_image_id: id)
      .where(id:entity.id)

upsertCompanyImage = (entity, blob) ->
  upsertImage(entity,blob, tables.user.company)

updatePassword = (user, password, overwrite = true) ->
  createPasswordHash(password).then (password) ->
    toSet = if overwrite then password else tables.auth.user().raw("coalesce(password, '#{password}')")
    tables.auth.user().update(password: toSet)
    .where(id: user.id)

getIdentity = (req) ->
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

verifyValidAccount = (user) ->
  return unless user
  return user if user.is_superuser
  if !user.email_is_valid
    throw new userSessionErrors.InValidEmailError("User's email has not been verified.")
  if !user.is_active
    throw new userSessionErrors.InActiveUserError("User is not valid due to inactive account.")
  user

module.exports =
  createPasswordHash: createPasswordHash
  verifyPassword: verifyPassword
  verifyValidAccount: verifyValidAccount
  getProfile: profileSvc.getFirst
  updateCurrentProfile: profileSvc.updateCurrent
  updateProfile: profileSvc.update
  getProfiles: profileSvc.getProfiles
  getImage: getImage
  upsertImage: upsertImage
  upsertCompanyImage: upsertCompanyImage
  updatePassword: updatePassword
  getIdentity: getIdentity
