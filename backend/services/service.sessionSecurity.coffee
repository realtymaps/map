Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require('../config/logger').spawn("service:sessionSecurity")
keystore = require '../services/service.keystore'
uuid = require '../utils/util.uuid'
config = require '../config/config'
tables = require '../config/tables'
subscriptionSvc = require './service.user_subscription.coffee'
userUtils = require '../utils/util.user'
errors = require '../utils/errors/util.errors.userSession'


# creates a bcrypt hash, without the built-in salt
hashToken = (token, salt) ->
  bcrypt.hashAsync(token, salt)
  .then (tokenHash) ->
    tokenHash.substring(salt.length)


# correctly sets the security cookie, depending on whether rememberMe is desired
setSecurityCookie = (req, res, token, rememberMe) ->
  if rememberMe
    options = _.clone(config.SESSION_SECURITY.cookie)
    options.maxAge = config.SESSION_SECURITY.rememberMeAge
  else
    options = config.SESSION_SECURITY.cookie
  # cookie has 3 parts: userid, sessionid, and the token (before hashing)
  res.cookie config.SESSION_SECURITY.name, "#{req.user.id}.#{req.sessionID}.#{token}", options


# this is for when new logins occur, or when we want to create a session based on rememberMe
createNewSeries = (req, res, rememberMe) ->
  token = uuid.genToken()
  keystore.cache.getValue('token', namespace: 'hashing cost factors')
  .then (tokenCostFactor) ->
    bcrypt.genSaltAsync(tokenCostFactor)
  .then (salt) ->
    hashToken(token, salt)
    .then (tokenHash) ->
      tables.auth.sessionSecurity()
      .insert
        user_id: req.user.id
        session_id: req.sessionID
        remember_me: rememberMe
        series_salt: salt
        # here we store the hash, not the token, for the same reason you do
        # that with passwords -- someone who gets some db data they shouldn't
        # won't be able to use it to log in as someone else (easily)
        token: tokenHash
  .then () ->
    setSecurityCookie(req, res, token, req.body.remember_me)


# figures out how many logins the user should have, and culls away enough to
# make "room" for a new one
ensureSessionCount = (req) -> Promise.try () ->
  if not req.user
    logger.debug () -> "ensureSessionCount: anonymous users don't get session-counted"
    return Promise.resolve()
  if req.session.permissions['unlimited_logins']
    logger.debug () -> "ensureSessionCount for #{req.user.username}: unlimited logins allowed"
    return Promise.resolve()
  maxLoginsPromise = keystore.cache.getValuesMap('plans')
  .then (plans) ->
    logger.debug plans

    groups = Object.keys(req.session.groups)

    if !groups.length
      throw new errors.NeedsGroupPermissions('User has no groups')

    plan =_.find Object.keys(plans), (p) ->
      !!req.session.groups[p.toInitCaps() + ' Tier']

    if !plan
      logger.info 'groups: ' + groups.join(',')
      logger.info 'plans: '+ Object.keys(plans).join(',')
      throw new errors.InValidPlanError('plan not found')

    plan.maxLogins

  sessionSecuritiesPromise = tables.auth.sessionSecurity().whereNotExists () ->
    @select(1).from(tables.auth.session.tableName)
    .where(sid: "#{tables.auth.sessionSecurity.tableName}.session_id")
  .delete()
  .then () ->
    tables.auth.sessionSecurity()
    .where(user_id: req.user.id)
  .then (sessionSecurities=[]) ->
    sessionSecurities

  Promise.join maxLoginsPromise, sessionSecuritiesPromise, (maxLogins, sessionSecurities) ->
    if maxLogins <= sessionSecurities.length
      logger.debug "ensureSessionCount for #{req.user.username}: invalidating #{sessionSecurities.length-maxLogins+1} existing logins"
      sessionIdsToDelete = _.pluck(_.sortBy(sessionSecurities, 'rm_modified_time').slice(0, sessionSecurities.length-maxLogins+1), 'session_id')
      tables.auth.sessionSecurity()
      .whereIn('session_id', sessionIdsToDelete)
      .delete()


deleteSecurities = (criteria) ->
  tables.auth.sessionSecurity()
  .where(criteria)
  .delete()


getSecuritiesForSession = (sessionId) ->
  tables.auth.sessionSecurity()
  .where(session_id: sessionId)
  .then (securities=[]) ->
    securities


sessionLoginProcess = (req, res, user) ->
  subscriptionSvc.getStatus user
  .then (subscription_status) ->
    req.user = user
    req.session.subscription = subscription_status
    userUtils.cacheUserValues(req)

  .then () ->
    req.session.saveAsync()
  .then () ->
    ensureSessionCount(req)
  .then () ->
    createNewSeries(req, res, !!req.body.remember_me)


module.exports = {
  createNewSeries
  ensureSessionCount
  deleteSecurities
  getSecuritiesForSession
  hashToken
  sessionLoginProcess
}