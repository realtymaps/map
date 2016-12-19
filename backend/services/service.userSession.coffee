Promise = require 'bluebird'
bcrypt = require 'bcrypt'
logger = require('../config/logger').spawn("session:userSession:service")
keystore = require '../services/service.keystore'
uuid = require '../utils/util.uuid'
tables = require '../config/tables'
userSessionErrors = require '../utils/errors/util.errors.userSession'
frontendRoutes = require '../../common/config/routes.frontend'
dbs = require '../config/dbs'

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
    return bcrypt.hashAsync(password, passwordCostFactor)
  .then (hash) -> return "bcrypt$#{hash}"


verifyPassword = (email, password) ->
  tables.auth.user()
  .whereRaw("LOWER(email) = ?", "#{email}".toLowerCase())
  .then (user=[]) ->
    user[0] ? {}
  .then (user) ->
    if not user or not user?.password
      # best practice is to go ahead and hash the password before returning,
      # to prevent timing attacks from determining validity of email
      return createPasswordHash(password).then () -> return false
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
        if hashData.needsUpdate
          # in the background, update this user's hash
          logger.info "updating password hash for email: #{email}"
          createPasswordHash(password)
          .then (hash) -> _updateUser(user.id, password: hash)
          .catch (err) -> logger.error "failed to update password hash for userid #{user.id}: #{err}"
        return user

updatePassword = (user, password, transaction, overwrite = true) ->
  createPasswordHash(password).then (password) ->
    toSet = if overwrite then password else tables.auth.user().raw("coalesce(password, ?)", password)
    tables.auth.user({transaction}).update(password: toSet)
    .where(id: user.id)

# This method is invoked when a user clicks the "Forgot Password" link
requestResetPassword = (email, host) ->
  if !email
    throw new Error('Email required')

  tables.auth.user().select('id', 'email', 'first_name', 'last_name', 'username')
  .where('email', email)
  .then ([user]) ->
    if !user
      throw new Error('User not found')

    # save important information for client login later in keystore
    # `passwordResetObj` also has data for vero template, so we send it there too
    passwordResetKey = uuid.genUUID()
    reset_url = "http://#{host}/#{frontendRoutes.passwordReset.replace(':key', passwordResetKey)}"

    passwordResetObj =
      user: user
      evtdata:
        name: 'password_reset'
        verify_host: host
        reset_url: reset_url

    keystore.setValue(passwordResetKey, passwordResetObj, namespace: 'password-reset')
    .then () ->
      require('./email/vero').then (veroSvc) ->
        require('../config/logger').spawn('vero:debug').debug(veroSvc)
        veroSvc.vero.createUserAndTrackEvent(
          veroSvc.user.getUniqueUserId(user)
          user.email
          user
          passwordResetObj.evtdata.name
          passwordResetObj
        )
  .catch (err) ->
    logger.debug err
    throw err

# This method is invoked when a user clicks the link to the password reset page
getResetPassword = (key) ->
  keystore.getValue key, namespace: 'password-reset'
  .then (entry) ->
    email: entry.user.email
    first_name: entry.user.first_name
    last_name: entry.user.last_name
    username: entry.user.username
  .catch (err) ->
    logger.debug err
    throw err

# This method is invoked when the user submits a new password via the reset form
doResetPassword = ({key, password}) ->
  dbs.transaction 'main', (trx) ->
    keystore.getValue key, namespace: 'password-reset', transaction: trx
    .then (entry) ->
      updatePassword(id: entry.user.id, password, trx, true)
      .then () ->
        keystore.deleteValue('password-reset', key, trx)
  .catch (err) ->
    logger.debug err
    throw err

verifyValidAccount = (user) ->
  return unless user
  return user if user.is_superuser

  if !user.is_active
    throw new userSessionErrors.InActiveUserError("User is not valid due to inactive account.")
  user

module.exports = {
  createPasswordHash
  verifyPassword
  verifyValidAccount
  updatePassword
  requestResetPassword
  getResetPassword
  doResetPassword
}
