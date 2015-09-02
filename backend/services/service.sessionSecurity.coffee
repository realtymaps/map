Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
SessionSecurity = require '../models/model.sessionSecurity'
environmentSettingsService = require '../services/service.environmentSettings'
uuid = require '../utils/util.uuid'
config = require '../config/config'
dbs = require '../config/dbs'


CLEAN_SESSION_SECURITY = "DELETE FROM session_security WHERE app = '#{config.SESSION_SECURITY.app}' AND session_id IN (SELECT session_id FROM session_security LEFT JOIN session ON session.sid=session_security.session_id WHERE sid IS NULL);"


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
  environmentSettingsService.getSettings()
  .then (settings) ->
    bcrypt.genSaltAsync(settings['token hashing cost factor'])
  .then (salt) ->
    hashToken(token, salt)
    .then (tokenHash) ->
      security =
        user_id: req.user.id
        session_id: req.sessionID
        remember_me: rememberMe
        series_salt: salt
        app: config.SESSION_SECURITY.app
        # here we store the hash, not the token, for the same reason you do
        # that with passwords -- someone who gets some db data they shouldn't
        # won't be able to use it to log in as someone else (easily)
        token: tokenHash
      return security
  .then (security) ->
    SessionSecurity.forge(security).save()
  .then () ->
    setSecurityCookie(req, res, token, req.body.remember_me)


# figures out how many logins the user should have, and culls away enough to
# make "room" for a new one
ensureSessionCount = (req) -> Promise.try () ->
  if not req.user
    #logger.debug "ensureSessionCount: anonymous users don't get session-counted"
    return Promise.resolve()
  if req.session.permissions['unlimited_logins']
    #logger.debug "ensureSessionCount for #{req.user.username}: unlimited logins allowed"
    return Promise.resolve()
  maxLoginsPromise = environmentSettingsService.getSettings()
  .then (settings) ->
    if req.session.groups['Premium Tier']
      return settings['default premium logins']
    if req.session.groups['Standard Tier']
      return settings['default standard logins']
    if req.session.groups['Basic Tier']
      return settings['default basic logins']
    if req.session.groups['Free Tier']
      return settings['default free logins']

  sessionSecuritiesPromise = dbs.users.raw(CLEAN_SESSION_SECURITY)
  .then () ->
    SessionSecurity.where(user_id: req.user.id, app: config.SESSION_SECURITY.app).fetchAll()
  .then (sessionSecurities) ->
    return sessionSecurities.toJSON()

  Promise.join maxLoginsPromise, sessionSecuritiesPromise, (maxLogins, sessionSecurities) ->
    #logger.debug "ensureSessionCount for #{req.user.username}: #{maxLogins} logins allowed, #{sessionSecurities.length} existing logins found"
    if maxLogins <= sessionSecurities.length
      logger.debug "ensureSessionCount for #{req.user.username}: invalidating #{sessionSecurities.length-maxLogins+1} existing logins"
      sessionIdsToDelete = _.pluck(_.sortBy(sessionSecurities, 'updated_at').slice(0, sessionSecurities.length-maxLogins+1), 'session_id')
      SessionSecurity.knex().whereIn('session_id', sessionIdsToDelete).where(app: config.SESSION_SECURITY.app).del()


deleteSecurities = (criteria) ->
  SessionSecurity.knex().where(criteria).where(app: config.SESSION_SECURITY.app).del()


getSecuritiesForSession = (sessionId) ->
  SessionSecurity.where(session_id: sessionId).where(app: config.SESSION_SECURITY.app).fetchAll()
  .then (securities) ->
    return securities.toJSON()


module.exports =
  createNewSeries: createNewSeries
  ensureSessionCount: ensureSessionCount
  deleteSecurities: deleteSecurities
  getSecuritiesForSession: getSecuritiesForSession
  hashToken: hashToken
