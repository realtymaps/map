Promise = require 'bluebird'
bcrypt = require 'bcrypt'
logger = require('../config/logger').spawn("session:userSession:service")
keystore = require '../services/service.keystore'
tables = require '../config/tables'
userSessionErrors = require '../utils/errors/util.errors.userSession'

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

updatePassword = (user, password, overwrite = true) ->
  createPasswordHash(password).then (password) ->
    toSet = if overwrite then password else tables.auth.user().raw("coalesce(password, '#{password}')")
    tables.auth.user().update(password: toSet)
    .where(id: user.id)

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
}
