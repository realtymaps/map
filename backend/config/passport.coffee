BasicStrategy = require('passport-http').BasicStrategy
UserPermissionModels = require("../models/userPermissionModels")

module.exports = (passport) ->

  passport.use new BasicStrategy ({}), (username, password, done) ->
    UserPermissionModels.User.forge({ username: username }).fetch().then (user) ->
      if not user then return done(null, false)
      if not user.authenticate(password) then return done(null, false)
      return done(null, user)
    .catch(done)

  passport.serializeUser (user, done) ->
    done(null, user)

  passport.deserializeUser (user, done) ->
    done(null, user)
 