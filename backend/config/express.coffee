express = require 'express'
passport = require 'passport'
path = require 'path'

config = require './config'
dbs = require './dbs'
logger = require './logger'

# express midlewares
helmet = require 'helmet'
multipart = require 'connect-multiparty'
session = require 'express-session'
sessionStore = require('connect-pg-simple')(session)
compress = require 'compression'
bodyParser = require 'body-parser'
favicon = require 'static-favicon'
cookieParser = require 'cookie-parser'
methodOverride = require 'method-override'
serveStatic = require 'serve-static'
errorHandler = require 'errorhandler'
connectFlash = require 'connect-flash'


app = express()

# JWI: none of these are necessary
# set port, routes, models and config paths
#app.set 'port', config.PORT
#app.set 'routes', path.join(config.ROOT_PATH, '/routes/')
#app.set 'models', path.join(config.ROOT_PATH, '/data_access/models/')
#app.set 'config', config


# security headers
app.use helmet.xframe()
app.use helmet.iexss()
app.use helmet.contentTypeOptions()
app.use helmet.cacheControl()

# ensure all assets and data are compressed - above static
app.use compress()

# setting the favicon and static folder

app.use favicon "#{config.FRONTEND_ASSETS_PATH}/assets/favicon.ico"
app.use serveStatic config.FRONTEND_ASSETS_PATH

# cookie parser - above session
app.use cookieParser config.SESSION.secret

# body parsing middleware - above methodOverride()
app.use bodyParser()
app.use multipart()
app.use methodOverride()

# session store (postgres)
config.SESSION.store = new sessionStore(config.SESSION_STORE)
app.use session(config.SESSION)

# let passport manage sessions
app.use passport.initialize()
app.use passport.session()

# enable flash messages
app.use connectFlash()


# bootstrap routes
require("../routes")(app)

app.use (err, req, res, next) ->
  logger.error "uncaught error found by express:"
  logger.error err.toString()
  next()

if config.ENV is 'development'
  app.use errorHandler { dumpExceptions: true, showStack: true }
  app.set("trust proxy", 1)

module.exports = app
