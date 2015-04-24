_ = require 'lodash'
path = require 'path'
common =  require '../../common/config/commonConfig'

#console.info "ENV: !!!!!!!!!!!!!!!!!!! %j", process.env
base =
  PROC_COUNT: parseInt(process.env.WEB_CONCURRENCY) || require('os').cpus().length
  ENV: process.env.NODE_ENV || 'development'
  ROOT_PATH: path.join(__dirname, '..')
  FRONTEND_ASSETS_PATH: path.join(__dirname, '../../_public')
  PORT: '/tmp/nginx.socket'  # unix domain socket, unless overriden below for dev
  LOGGING:
    PATH: "mean.coffee.log"
    LEVEL: 'info'
    FILE_AND_LINE: false
    LONG_STACK_TRACES: false
  USER_DB:
    client: 'pg'
    connection: process.env.USER_DATABASE_URL
    pool:
      min: 2
      max: 10
  PROPERTY_DB:
    client: 'pg'
    connection: process.env.PROPERTY_DATABASE_URL
    pool:
      min: 2
      max: 10
  TRUST_PROXY: 1
  SESSION:
    secret: "thisistheREALTYMAPSsecretforthesession"
    cookie:
      maxAge: null
      secure: true
    name: "connect.sid"
    resave: false
    saveUninitialized: true
    unset: "destroy"
  SESSION_SECURITY:
    name: "anticlone"
    app: "map"
    rememberMeAge: 30*24*60*60*1000 # 30 days
    cookie:
      httpOnly: true
      signed: true
      secure: true
  NODETIME: false
  USE_ERROR_HANDLER: false
  DB_CACHE_TIMES:
    SLOW_REFRESH: 60*1000   # 1 minute
    FAST_REFRESH: 30*1000   # 30 seconds
    PRE_FETCH: .1
  MEM_WATCH:
    IS_ON: false
  TEMP_DIR: '/tmp'
  LOB:
    TEST_API_KEY: process.env.LOB_TEST_API_KEY
    LIVE_API_KEY: process.env.LOB_LIVE_API_KEY
    API_VERSION: '2014-12-18'
  MAPBOX:
    API_KEY: process.env.MAPBOX_API_KEY
  MAP: common.map
  NEW_RELIC:
    LOGLEVEL: 'info'
    API_KEY: process.env.NEW_RELIC_API_KEY
  HIREFIRE:
    API_KEY: process.env.HIREFIRE_TOKEN

# this one's separated out so we can re-use the USER_DB.connection value
base.SESSION_STORE =
  conString: base.USER_DB.connection


# use environment-specific configuration as little as possible
environmentConfig =

  development:
    PORT: process.env.PORT || 4000
    USER_DB:
      debug: false # set to true for verbose db logging on the user db
    PROPERTY_DB:
      debug: false # set to true for verbose db logging on the properties db
    TRUST_PROXY: false
    SESSION:
      cookie:
        secure: false
    SESSION_SECURITY:
      cookie:
        secure: false
    LOGGING:
      LEVEL: 'sql'
      FILE_AND_LINE: true
      LONG_STACK_TRACES: !!process.env.LONG_STACK_TRACES
    USE_ERROR_HANDLER: true
    NEW_RELIC:
      RUN: false # can be flipped to true if needed for troubleshooting or testing
      LOGLEVEL: 'info'
      APP_NAME: if process.env.INSTANCE_NAME then "#{process.env.INSTANCE_NAME}-dev-realtymaps-map" else null

  test: # test inherits from development below
    LOGGING:
      LEVEL: 'debug'
    MEM_WATCH:
      IS_ON: true

  staging:
    DB_CACHE_TIMES:
      SLOW_REFRESH: 5*60*1000   # 5 minutes
      FAST_REFRESH: 60*1000     # 1 minute
    LOGGING:
      LONG_STACK_TRACES: !!process.env.LONG_STACK_TRACES
    # the proxy and secure settings below need to be removed when we start using nginx
    TRUST_PROXY: false
    SESSION:
      cookie:
        secure: false
    SESSION_SECURITY:
      cookie:
        secure: false
    NEW_RELIC:
      RUN: true
      LOGLEVEL: 'info'
      APP_NAME: if process.env.INSTANCE_NAME then "#{process.env.INSTANCE_NAME}-staging-realtymaps-map" else null

  production:
    DB_CACHE_TIMES:
      SLOW_REFRESH: 10*60*1000   # 10 minutes
      FAST_REFRESH: 60*1000      # 1 minute
    MEM_WATCH:
      IS_ON: true
  # the proxy and secure settings below need to be removed when we start using nginx
    TRUST_PROXY: false
    SESSION:
      cookie:
        secure: false
    SESSION_SECURITY:
      cookie:
        secure: false
    NEW_RELIC:
      RUN: true
      APP_NAME: "realtymaps-map"

environmentConfig.test = _.merge({}, environmentConfig.development, environmentConfig.test)

config = _.merge({}, base, environmentConfig[base.ENV])
# console.log "config: "+JSON.stringify(config, null, 2)

module.exports = config

# have to set a secret backend-only route
backendRoutes = require('../../common/config/routes.backend')
backendRoutes.hirefire =
  info: "/hirefire/#{config.HIREFIRE.API_KEY}/info"
