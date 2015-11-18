config = require './config'
if config.NEW_RELIC.RUN
  newrelic = require 'newrelic'
else
  newrelic =
    getBrowserTimingHeader: () ->
      '<!-- NEWRELIC NOT LOADED -->'

express = require 'express'
path = require 'path'
Promise = require 'bluebird'
paths = require '../../common/config/paths'
_ = require 'lodash'

commonConfig = require '../../common/config/commonConfig'
dbs = require './dbs'
logger = require './logger'
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
cls = require 'continuation-local-storage'
patchNamespaceForPromise = require 'cls-bluebird'
promisify = require './promisify'
sessionSecurity = require '../services/service.sessionSecurity'
status = require '../../common/utils/httpStatus'

namespace = cls.createNamespace config.NAMESPACE

app = express()

swagger = require 'swagger-tools'

# security headers
app.use helmet.xframe()
app.use helmet.xssFilter()
app.use helmet.nosniff()
app.use helmet.nocache()

# ensure all assets and data are compressed - above static
app.use compress()

app.use serveStatic config.FRONTEND_ASSETS_PATH

# cookie parser - above session
app.use cookieParser config.SESSION.secret

# body parsing middleware - above methodOverride()
app.use bodyParser.urlencoded(extended: true)
app.use bodyParser.json()
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


#ability to get request and transaction id without callback hell
#http://stackoverflow.com/questions/12575858/is-it-possible-to-get-the-current-request-that-is-being-served-by-node-js
#DOMAINS ARE deprecated so we are going with continuation-local-storage instead. Which appears to be cleaner anyhow.
###
###
# create a transaction id for each request
app.use (req, res, next) ->
  transactionId = uuid.genUUID()
  #wrap/bind namespace's life span to the life of a req/res
  patchNamespaceForPromise namespace
  namespace.bindEmitter req
  namespace.bindEmitter res
  namespace.run ->
    namespace.set 'transactionId', transactionId
    namespace.set 'req', req
    next()

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
  if data instanceof ExpressResponse
    # this response is intentional
    if !status.isWithinOK(data.status)
      # this is not strictly an error handler now, it is also used for routine final handling of a response,
      # something not easily done with the standard way of using express -- so only log as an error if the
      # status indicates that it is
      logger.error (data.toString())

    return data.send(res)

  # otherwise, it's probably a thrown Error
  logger.error('uncaught error found by express:')
  analysis = analyzeValue(data)
  logger.error(analysis.toString())
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
  google: require('./googleMaps').locals

app.set('views', __dirname.replace('/config','/views'))
app.set('view engine', 'jade')

module.exports = app
