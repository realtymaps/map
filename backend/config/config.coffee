_ = require 'lodash'
path = require 'path'
common =  require '../../common/config/commonConfig.coffee'


base =
  NAMESPACE: 'rmaps'
  JQ_QUEUE_NAME: process.env.JQ_QUEUE_NAME || null
  PROC_COUNT: parseInt(process.env.WEB_CONCURRENCY) || require('os').cpus().length
  ENV: process.env.NODE_ENV || 'development'
  ROOT_PATH: path.join(__dirname, '..')
  FRONTEND_ASSETS_PATH: path.join(__dirname, '../../_public')
  PORT: process.env.PORT_GOD || (if process.env.NGINX_SOCKET_FILENAME then "./nginx/#{process.env.NGINX_SOCKET_FILENAME}" else false) || parseInt(process.env.PORT) || 4000
  LOGGING:
    PATH: 'rmaps.log'
    LEVEL: process.env.LOG_LEVEL ? 'debug'
    FILE_AND_LINE: false
    ENABLE: process.env.LOG_ENABLE ? '-stylus:*,-frontend:*,-backend:*,-test:*'

  DBS:
    MAIN:
      client: 'pg'
      connection: process.env.MAIN_DATABASE_URL
      pool:
        min: 2
        max: if process.env.JQ_QUEUE_NAME then 8 else 10
        # 10 minutes -- this is an arbitrary long time, we might want to bump this up or down if we see problems
        pingTimeout: 10*60*1000
    RAW_TEMP:
      client: 'pg'
      connection: process.env.RAW_TEMP_DATABASE_URL
      pool:
        min: 2
        max: if process.env.JQ_QUEUE_NAME then 8 else 10
        # 10 minutes -- this is an arbitrary long time, we might want to bump this up or down if we see problems
        pingTimeout: 10*60*1000
  TRUST_PROXY: 1
  SESSION:
    secret: 'thisistheREALTYMAPSsecretforthesession'
    cookie:
      maxAge: null
      secure: true
    name: 'connect.sid'
    resave: false
    saveUninitialized: true
    unset: 'destroy'
  SESSION_SECURITY:
    name: 'anticlone'
    app: 'map'
    rememberMeAge: 30*24*60*60*1000 # 30 days
    cookie:
      httpOnly: true
      signed: true
      secure: true
  USE_ERROR_HANDLER: false
  MEM_WATCH:
    IS_ON: process.env.MEM_WATCH_IS_ON || false
  TEMP_DIR: '/tmp'
  MAP: common.map
  IMAGES: common.images
  VALIDATION: common.validation
  NEW_RELIC:
    LOGLEVEL: 'info'
    API_KEY: process.env.NEW_RELIC_API_KEY
  HIREFIRE:
    API_KEY: process.env.HIREFIRE_TOKEN
    BACKUP:
      DO_BACKUP: process.env.HIREFIRE_BACKUP == 'true'
      RUN_WINDOW: 120000  # 2 minutes
      DELAY_VARIATION: 10000  # 10 seconds
  ENCRYPTION_AT_REST: process.env.ENCRYPTION_AT_REST
  JOB_QUEUE:
    LOCK_KEY: 0x1693F8A6  # random number
    SCHEDULING_LOCK_ID: 0
    MAINTENANCE_LOCK_ID: 1
    MAINTENANCE_WINDOW: 30000  # 30 seconds
    SUBTASK_ZOMBIE_SLACK: "INTERVAL '1 minute'"
    LOCK_DEBUG: process.env.LOCK_DEBUG
  CLEANUP:
    OLD_TABLE_DAYS: 7
    SUBTASK_ERROR_DAYS: 90
    OLD_DELETE_MARKER_DAYS: 7
  EMAIL_VERIFY:
    HASH_MIN_LENGTH: 20


# this one's separated out so we can re-use the DBS.MAIN.connection value
base.SESSION_STORE =
  conString: base.DBS.MAIN.connection
  tableName: 'auth_session'


# use environment-specific configuration as little as possible
environmentConfig =

  development:
    DBS:
      MAIN:
        debug: false # set to true for verbose logging
      RAW_TEMP:
        debug: false # set to true for verbose logging
    TRUST_PROXY: false
    SESSION:
      cookie:
        secure: false
    SESSION_SECURITY:
      cookie:
        secure: false
    LOGGING:
      FILE_AND_LINE: true
    USE_ERROR_HANDLER: true
    NEW_RELIC:
      RUN: Boolean(process.env.NEW_RELIC_RUN)
      LOGLEVEL: 'info'
      APP_NAME: if process.env.RMAPS_MAP_INSTANCE_NAME then "#{process.env.RMAPS_MAP_INSTANCE_NAME}-dev-realtymaps-map" else null
    CLEANUP:
      OLD_TABLE_DAYS: 1
      SUBTASK_ERROR_DAYS: 7
      OLD_DELETE_MARKER_DAYS: 1

  test: # test inherits from development below
    LOGGING:
      LEVEL: 'info'
    MEM_WATCH:
      IS_ON: true

  staging:
    # the proxy and secure settings below need to be removed when we start using the heroku SSL endpoint
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
      APP_NAME: if process.env.RMAPS_MAP_INSTANCE_NAME then "#{process.env.RMAPS_MAP_INSTANCE_NAME}-staging-realtymaps-map" else null

  production:
    MEM_WATCH:
      IS_ON: true
    # the proxy and secure settings below need to be removed when we start using the heroku SSL endpoint
    TRUST_PROXY: false
    SESSION:
      cookie:
        secure: false
    SESSION_SECURITY:
      cookie:
        secure: false
    NEW_RELIC:
      RUN: true
      APP_NAME: 'realtymaps-map'

environmentConfig.test = _.merge({}, environmentConfig.development, environmentConfig.test)

config = _.merge({}, base, environmentConfig[base.ENV])


module.exports = config

# have to set a secret backend-only route
backendRoutes = require('../../common/config/routes.backend.coffee')
backendRoutes.hirefire =
  info: "/hirefire/#{config.HIREFIRE.API_KEY}/info"
