express = require 'express'
path = require 'path'
Promise = require 'bluebird'

config = require './config'
dbs = require './dbs'
logger = require './logger'
auth = require '../utils/util.auth'
uuid = require '../utils/util.uuid'

# express midlewares
helmet = require 'helmet'
multipart = require 'connect-multiparty'
session = require 'express-session'
sessionStore = require('connect-pg-simple')(session)
compress = require 'compression'
bodyParser = require 'body-parser'
favicon = require 'serve-favicon'
cookieParser = require 'cookie-parser'
methodOverride = require 'method-override'
serveStatic = require 'serve-static'
errorHandler = require 'errorhandler'
connectFlash = require 'connect-flash'
promisifyMiddleware = require('./promisify').middleware
sessionSecurity = require '../services/service.sessionSecurity'
status = require '../../common/utils/httpStatus'
livereload = require "connect-livereload"

app = express()

# JWI: none of these are necessary
# set port, routes, models and config paths
#app.set 'port', config.PORT
#app.set 'routes', path.join(config.ROOT_PATH, '/routes/')
#app.set 'models', path.join(config.ROOT_PATH, '/data_access/models/')
#app.set 'config', config


# security headers
app.use helmet.xframe()
app.use helmet.xssFilter()
app.use helmet.nosniff()
app.use helmet.nocache()

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
config.SESSION_STORE.pg = dbs.pg
config.SESSION.store = new sessionStore(config.SESSION_STORE)
config.SESSION.genid = uuid.genUUID
app.use session(config.SESSION)


# promisify sessions
app.use Promise.nodeifyWrapper(promisifyMiddleware.promisifySession)

# do login session management
app.use Promise.nodeifyWrapper(auth.setSessionCredentials)

# do session security checks
app.use Promise.nodeifyWrapper(auth.checkSessionSecurity)

# enable flash messages
app.use connectFlash()

if config.PORT != config.PROD_PORT
  app.use livereload
    port: 35729
    ignore: []#[".js",".svg"] example

# bootstrap routes
require("../routes")(app)

nomsg = ""

app.use (err, req, res, next) ->
  if err.status?
    #if we have a status then it is handled and not severe.
    # send the Error code to client along with a possible message
    msg = if err.message? then err.message else nomsg
    return res.status(err.status).send msg

  logger.error "uncaught error found by express:"
  logger.error (if err.stack then ''+err.stack else ''+err)
  res.status(status.INTERNAL_SERVER_ERROR).json(error: err.message)
  next()

if config.USE_ERROR_HANDLER
  app.use errorHandler { dumpExceptions: true, showStack: true }

app.set("trust proxy", config.TRUST_PROXY)


module.exports = app
