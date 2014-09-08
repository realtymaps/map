auth = require '../config/auth'


module.exports = (app) ->

  app.post '/login', auth.requireLogin(), (req, res, next) ->
    res.json({ msg: "success?"})

  # we don't require you to be logged in to hit the logout button; that could
  # be confusing for users with a session that has been killed for one reason
  # or another (they would click logout and are then asked to login, if they
  # do then they are logged out...)
  app.get '/logout', auth.allowAll(), (req, res, next) ->
    # only call req.logout() if it exists, i.e. if the user is logged in 
    req.logout?()
    res.redirect('/')

###
  app.post '/signup', auth.none, (req, res) ->
  
###
