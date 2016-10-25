# this file's basename can't be 'express' or else it confuses newrelic

config = require './config'

newrelic = require './newrelic'
express = require 'express'
path = require 'path'
Promise = require 'bluebird'
paths = require '../../common/config/paths'
_ = require 'lodash'

commonConfig = require '../../common/config/commonConfig'
dbs = require './dbs'
logger = require('./logger').spawn('express')
auth = require '../utils/util.auth'
uuid = require '../utils/util.uuid'
ExpressResponse = require '../utils/util.expressResponse'
analyzeValue = require '../../common/utils/util.analyzeValue'
escape = require('escape-html')

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
promisify = require './promisify'
sessionSecurity = require '../services/service.sessionSecurity'
status = require '../../common/utils/httpStatus'

app = express()

swagger = require 'swagger-tools'

# security headers
app.use helmet.xframe()
app.use helmet.xssFilter()
app.use helmet.nosniff()
app.use helmet.nocache()

# ensure all assets and data are compressed - above static
app.use compress()

app.use serveStatic(config.FRONTEND_ASSETS.PATH, {
  setHeaders: (res, path) ->
    # Turn on caching headers for images
    if path.match(/\.(png|jpg|svg|gif)$/)
      res.setHeader('Cache-Control', "public, max-age=#{config.FRONTEND_ASSETS.MAX_AGE_SEC}")
})

# cookie parser - above session
app.use cookieParser config.SESSION.secret

# body parsing middleware - above methodOverride()
app.use bodyParser.urlencoded(extended: true)
app.use bodyParser.json(limit: '5mb')
app.use multipart()
app.use methodOverride()


# session store (postgres)
config.SESSION_STORE.pg = dbs.get('pg')
config.SESSION.store = new sessionStore(config.SESSION_STORE)
config.SESSION.genid = uuid.genUUID
app.use session(config.SESSION)


# promisify sessions
app.use Promise.nodeifyWrapper(promisify.sessionMiddleware)

# do login session management
app.use Promise.nodeifyWrapper(auth.setSessionCredentials)

# do session security checks
app.use Promise.nodeifyWrapper(auth.checkSessionSecurity)

# enable flash messages
app.use connectFlash()

swaggerObject = require('js-yaml').load(require('fs').readFileSync(__dirname + '/swagger.yaml'))
swagger.initializeMiddleware swaggerObject, (middleware) ->
  # This middleware is required by the other swagger middlewares
  app.use middleware.swaggerMetadata()

  # Validate requests only, not responses
  # Response validation could be enabled once we have some nicer handling for validation errors
  #  It is not clear to me how to do this since swaggerValidator wraps res.end()
  app.use middleware.swaggerValidator
    validateResponse: false

  # This code could be enabled to turn on routing middleware
  # app.use middleware.swaggerRouter
  #   useStubs: true
  #   controllers: __dirname + '/../routes'

  # This middleware provides interactive API docs
  if process.env.NODE_ENV == 'development'
    app.use middleware.swaggerUi()

# bootstrap routes
require('../routes')(app)

app.use (data, req, res, next) ->
  logger.debug 'ExpressResponse Middleware'
  if data instanceof ExpressResponse
    # this response is intentional
    logger.debug "data.status: #{data.status}"
    if !status.isWithinOK(data.status) && !data.quiet
      # this is not strictly an error handler now, it is also used for routine final handling of a response,
      # something not easily done with the standard way of using express -- so only log as an error if the
      # status indicates that it is
      logger.error(data.toString())

    return data.send(res)

  # otherwise, it's probably a thrown Error
  logger.error('uncaught error found by express:')
  analysis = analyzeValue(data)
  logger.error(analysis.toString())

  if !res.headersSent
    res.status(status.INTERNAL_SERVER_ERROR).json alert:
      msg: commonConfig.UNEXPECTED_MESSAGE(escape(data.message))
      id: "500-#{req.path}"

  next()

if config.USE_ERROR_HANDLER
  app.use errorHandler { dumpExceptions: true, showStack: true }

app.set('trust proxy', config.TRUST_PROXY)

_.extend app.locals,
  newrelic: newrelic
  paths: paths

app.set('views', __dirname.replace('/config','/views'))
app.set('view engine', 'jade')

module.exports = app
