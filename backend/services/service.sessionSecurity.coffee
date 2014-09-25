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


createNewSeries = (req, res) ->
  if req.body.remember_me
    logger.debug "setting remember_me for user: #{req.user.username}"
  token = uuid()
  SessionSecurity.forge
    user_id: req.user.id
    session_id: req.sessionID
    remember_me: !!req.body.remember_me
    next_security_token: token
  .save()
  .then () ->
    if req.body.remember_me
      options = _.clone(config.SESSION_SECURITY)
      options.maxAge = config.SESSION_SECURITY.rememberMeAge
    else
      options = config.SESSION_SECURITY
    res.cookie config.SESSION_SECURITY.name, "#{req.sessionID}.#{token}", options

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
    SessionSecurity.forge(user_id: req.user.id).fetchAll()
  .then (sessionSecurities) ->
    return sessionSecurities.toJSON()
  
  Promise.join maxLoginsPromise, sessionSecuritiesPromise, (maxLogins, sessionSecurities) ->
    logger.debug "ensureSessionCount for #{req.user.username}: #{maxLogins} logins allowed, #{sessionSecurities.length} existing logins found"
    if maxLogins <= sessionSecurities.length
      logger.debug "ensureSessionCount for #{req.user.username}: invalidating #{sessionSecurities.length-maxLogins+1} existing logins"
      sessionIdsToDelete = _.pluck(_.sortBy(sessionSecurities, "updated_at").slice(0, maxLogins-1), 'session_id')
      SessionSecurity.knex.where('session_id', 'in', sessionIdsToDelete).del()


module.exports =
  createNewSeries: createNewSeries
  ensureSessionCount: ensureSessionCount

