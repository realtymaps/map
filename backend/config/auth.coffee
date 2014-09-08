passport = require("passport")

logger = require '../config/logger'


module.exports = {
  
  allowAll: () ->
    return (req, res, next) ->
      next()
  
  requireLogin: () ->
    return passport.authenticate('local', { session: false, successRedirect: "/success", failureRedirect: "/failure", failureFlash: true })
    
}
