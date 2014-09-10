passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

userService = require '../services/service.user'
logger = require '../config/logger'


passport.use new LocalStrategy ({}), (username, password, done) ->
  logger.debug "attempting to verify password for username: #{username}"
  userService.verifyPassword(username, password)
    .then (user) -> return done(null, user)
    .catch (error) ->
      logger.debug "failed authentication for username #{username}: #{error}"
      # hide the actual reason, we just need to report that it failed
      done(null, false, message: "Username and/or password do not match our records.")
  
passport.serializeUser (user, done) ->
  if not user or not user.id
    return done(new Error("user does not have a valid id"))
  else
    return done(null, user.id)

passport.deserializeUser (userid, done) ->
  logger.debug "attempting to deserialize user: #{userid}"
  userService.getUser({ id: userid })
    .then (user) ->
      logger.debug "got user from session: #{user.username}"
      done(null, user)
    .catch (err) ->
      logger.error "error deserializing userid: #{userid}"
      done(err, false)
