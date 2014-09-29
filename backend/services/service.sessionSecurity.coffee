Promise = require "bluebird"
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
SessionSecurity = require("../models/model.sessionSecurity")
environmentSettingsService = require("../services/service.environmentSettings")
uuid = require '../utils/util.uuid'
config = require '../config/config'
dbs = require '../config/dbs'


CLEAN_SESSION_SECURITY = 'DELETE FROM session_security WHERE session_id IN (SELECT session_id FROM session_security LEFT JOIN session ON session.sid=session_security.session_id WHERE sid IS NULL);'


hashToken = (token, salt) ->
  bcrypt.hashAsync(token, salt)
  .then (tokenHash) ->
    tokenHash.substring(salt.length)


setSecurityCookie = (req, res, token, rememberMe) ->
  if rememberMe
    options = _.clone(config.SESSION_SECURITY.cookie)
    options.maxAge = config.SESSION_SECURITY.rememberMeAge
  else
    options = config.SESSION_SECURITY.cookie
  res.cookie config.SESSION_SECURITY.name, "#{req.user.id}.#{req.sessionID}.#{token}", options


createNewSeries = (req, res) ->
  if req.body.remember_me
    logger.debug "setting remember_me for user: #{req.user.username}"
  token = uuid.genToken()
  logger.debug "############################################## new / token: #{token}"
  environmentSettingsService.getSettings()
  .then (settings) ->
    bcrypt.genSaltAsync(settings["token hashing cost factor"])
  .then (salt) ->
    logger.debug "############################################## new / salt: #{salt}"
    hashToken(token, salt)
    .then (tokenHash) ->
      logger.debug "############################################## new / hash: #{tokenHash}"
      security =
        user_id: req.user.id
        session_id: req.sessionID
        remember_me: !!req.body.remember_me
        series_salt: salt
        next_security_token: tokenHash
      return security
  .then (security) ->
    SessionSecurity.forge(security).save()
  .then () ->
    setSecurityCookie(req, res, token, req.body.remember_me)


ensureSessionCount = (req) -> Promise.try () ->
  if not req.user
    logger.debug "ensureSessionCount: anonymous users don't get session-counted"
    return Promise.resolve()
  if req.session.permissions["unlimited_logins"]
    logger.debug "ensureSessionCount for #{req.user.username}: unlimited logins allowed"
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
    SessionSecurity.where(user_id: req.user.id).fetchAll()
  .then (sessionSecurities) ->
    return sessionSecurities.toJSON()
  
  Promise.join maxLoginsPromise, sessionSecuritiesPromise, (maxLogins, sessionSecurities) ->
    logger.debug "ensureSessionCount for #{req.user.username}: #{maxLogins} logins allowed, #{sessionSecurities.length} existing logins found"
    if maxLogins <= sessionSecurities.length
      logger.debug "ensureSessionCount for #{req.user.username}: invalidating #{sessionSecurities.length-maxLogins+1} existing logins"
      sessionIdsToDelete = _.pluck(_.sortBy(sessionSecurities, "updated_at").slice(0, maxLogins-1), 'session_id')
      SessionSecurity.knex().where('session_id', 'in', sessionIdsToDelete).del()


deleteSecurities = (criteria) ->
  SessionSecurity.knex().where(criteria).del()

getSecuritiesForSession = (sessionId) ->
  SessionSecurity.where(session_id: sessionId).fetchAll()
  .then (securities) ->
    return securities.toJSON()

iterateSecurity = (req, res, security) ->
  token = uuid.genToken()
  hashToken(token, security.series_salt)
  .then (tokenHash) ->
    SessionSecurity.where
      id: security.id
      # this next criterium ensures we don't clobber another update
      next_security_token: security.next_security_token
    .save
      next_security_token: tokenHash
      current_security_token: security.next_security_token
      previous_security_token: security.current_security_token
      , {method: "update", patch: true}
    .then () ->
      SessionSecurity.forge(id: security.id).fetch()
    .then (new_security) ->
        new_security.toJSON()
    .then (new_security) ->
      if new_security.next_security_token == tokenHash
        # only if we detect that we successfully performed a save...
        setSecurityCookie(req, res, token, security.remember_me)

module.exports =
  createNewSeries: createNewSeries
  ensureSessionCount: ensureSessionCount
  deleteSecurities: deleteSecurities
  getSecuritiesForSession: getSecuritiesForSession
  iterateSecurity: iterateSecurity
  hashToken: hashToken
