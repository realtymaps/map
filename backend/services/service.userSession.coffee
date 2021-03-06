Promise = require 'bluebird'
bcrypt = require 'bcrypt'
logger = require('../config/logger').spawn("service:session")
keystore = require '../services/service.keystore'
uuid = require '../utils/util.uuid'
tables = require '../config/tables'
frontendRoutes = require '../../common/config/routes.frontend'
dbs = require '../config/dbs'
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'
analyzeValue = require '../../common/utils/util.analyzeValue'

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
    user[0]
  .then (user) ->
    if !user?.password
      # best practice is to go ahead and hash the password before returning,
      # to prevent timing attacks from determining validity of email
      return createPasswordHash(password).then () -> return false
    preprocessHash(user.password)
    .catch (err) ->
      throw new PartiallyHandledError(err, "error while preprocessing password hash for email #{email}")
    .then (hashData) ->
      Promise.try () ->
        switch hashData.algo
          when 'bcrypt'
            bcrypt.compareAsync(password, hashData.hash)
          else
            false
      .then (match) ->
        if !match
          return false
        if hashData.needsUpdate
          # in the background, update this user's hash
          logger.debug () -> "updating password hash for email: #{email}"
          createPasswordHash(password)
          .then (hash) -> _updateUser(user.id, password: hash)
          .catch (err) -> logger.error "failed to update password hash for user #{email}: #{analyzeValue.getFullDetails(err)}"
        return user

requestLoginToken = ({superuser, email}) ->
  if !email
    throw new Error('Email required')

  tables.auth.user().select('id', 'email')
  .where('email', email)
  .then ([user]) ->
    if !user
      throw new Error('User not found')

    loginToken = uuid.genUUID()

    createPasswordHash(loginToken).then (loginTokenHash) ->

      loginObj =
        superuser:
          email: superuser.email # not checked, just audit trail
        user: user
        login_token_hash: loginTokenHash

      keystore.setValue(email, loginObj, namespace: 'login-token')

      loginToken

  .catch (err) ->
    logger.debug err
    throw err

verifyLoginToken = ({email, loginToken}) ->
  tables.auth.user()
  .whereRaw("LOWER(email) = ?", "#{email}".toLowerCase())
  .then (user=[]) ->
    user[0]
  .then (user) ->
    dbs.transaction 'main', (trx) ->
      keystore.getValue email, namespace: 'login-token', transaction: trx
      .then (entry) ->
        if !user || !entry?.login_token_hash
          # best practice is to go ahead and hash the token before returning,
          # to prevent timing attacks from determining validity of email
          return createPasswordHash(loginToken).then () -> return false

        preprocessHash(entry.login_token_hash)
        .catch (err) ->
          throw new PartiallyHandledError(err, "error while preprocessing login token hash for email #{email}")
        .then (hashData) ->
          Promise.try () ->
            switch hashData.algo
              when 'bcrypt'
                bcrypt.compareAsync(loginToken, hashData.hash)
              else
                false
          .then (match) ->
            if !match
              return false

            keystore.deleteValue('login-token', email, trx)
            .then () ->
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

  tables.auth.user().select('id', 'email', 'first_name', 'last_name')
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
      require('./email/vero')
    .then (veroSvc) ->
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


module.exports = {
  createPasswordHash
  verifyPassword
  requestLoginToken
  verifyLoginToken
  updatePassword
  requestResetPassword
  getResetPassword
  doResetPassword
}
