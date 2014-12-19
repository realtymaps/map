express = require 'express'
path = require 'path'
Promise = require 'bluebird'

config = require './config'
dbs = require './dbs'
logger = require './logger'
auth = require '../utils/util.auth'
uuid = require '../utils/util.uuid'
ExpressResponse = require '../utils/util.expressResponse'
analyzeValue = require '../../common/utils/util.analyzeValue'

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
app.use bodyParser.urlencoded(extended: true)
app.use bodyParser.json()
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

app.use (data, req, res, next) ->
  if data instanceof ExpressResponse
    # this response is intentional
    payload = if data.payload? then data.payload else ""
    analysis = analyzeValue(payload)
    logger.error (JSON.stringify(analysis,null,2))
    return res.status(data.status).send payload

  # otherwise, it's probably a thrown Error
  analysis = analyzeValue(data)
  logger.error "uncaught error found by express:"
  logger.error (JSON.stringify(analysis,null,2))
  res.status(status.INTERNAL_SERVER_ERROR).json alert:
    msg: "Oops! Something unexpected happened! Please try again in a few minutes. If the problem continues, please let us know by emailing support@realtymaps.com, and giving us the following error message:<br/><code>#{data.message}</code>"
    id: "500-#{req.path}"
  next()

if config.USE_ERROR_HANDLER
  app.use errorHandler { dumpExceptions: true, showStack: true }

app.set("trust proxy", config.TRUST_PROXY)


module.exports = app
