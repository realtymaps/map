_ = require 'lodash'
path = require 'path'
common =  require '../../common/config/commonConfig.coffee'

scriptName = path.basename(require?.main?.filename, '.coffee')
if scriptName not in ['server','jobQueueWorker','queueNeedsWorker']
  scriptName = '__REPL'  # this makes it easier to use the result as keys in a hash


base =
  DYNO: process.env.DYNO || 'local'
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
    ENABLE: process.env.LOG_ENABLE ? ''  # 'frontend:*,backend:*,test:*'
    TIMESTAMP: process.env.LOG_TIMESTAMP == 'true'
    LOG_TO_FILE: process.env.LOG_TO_FILE == 'true'
  DBS:
    MAIN:
      client: 'pg'
      connection: process.env.MAIN_DATABASE_URL
      pool: pingTimeout: 20*60*1000
    RAW_TEMP:
      client: 'pg'
      connection: process.env.RAW_TEMP_DATABASE_URL
      pool: pingTimeout: 20*60*1000
    NORMALIZED:
      client: 'pg'
      connection: process.env.NORMALIZED_DATABASE_URL
      pool: pingTimeout: 20*60*1000
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
    API_KEY: process.env.HIREFIRE_TOKEN || 'dummy'
    RUN_WINDOW: 60000  # 1 minute
    WARN_THRESHOLD: 300000  # 5 minutes
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
  PAYMENT_PLATFORM:
    TRIAL_PERIOD_DAYS: 30
    LIVE_MODE: process.env.PAYMENT_IS_LIVE or false
    INTERVAL_COUNT: 1
    CURRENCY: 'usd'
  EMAIL_PLATFORM:
    LIVE_MODE: process.env.EMAIL_IS_LIVE or false
    MAX_RETRIES: 4
    RETRY_DELAY_MILLI: 2000
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
      RUN: if process.env.NEW_RELIC_RUN? then Boolean(process.env.NEW_RELIC_RUN) else false
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
      RUN: if process.env.NEW_RELIC_RUN? then Boolean(process.env.NEW_RELIC_RUN) else true
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
      RUN: if process.env.NEW_RELIC_RUN? then Boolean(process.env.NEW_RELIC_RUN) else true
      APP_NAME: 'realtymaps-map'


pools =
  server:
    MAIN:
      pool:
        min: 2
        max: 10
    RAW_TEMP:
      pool:
        min: 0
        max: 2
    NORMALIZED:
      pool:
        min: 0
        max: 2
  jobQueueWorker:
    MAIN:
      pool:
        min: 2
        max: 4
    RAW_TEMP:
      pool:
        min: 2
        max: 4
    NORMALIZED:
      pool:
        min: 2
        max: 4
  queueNeedsWorker:
    MAIN:
      pool:
        min: 1
        max: 2
    RAW_TEMP:
      pool:
        min: 0
        max: 2
    NORMALIZED:
      pool:
        min: 0
        max: 2
  __REPL:
    MAIN:
      pool:
        min: 2
        max: 4
    RAW_TEMP:
      pool:
        min: 2
        max: 4
    NORMALIZED:
      pool:
        min: 2
        max: 4


base.DBS = _.merge(base.DBS, pools[scriptName])
environmentConfig.test = _.merge({}, environmentConfig.development, environmentConfig.test)
config = _.merge({}, base, environmentConfig[base.ENV])


module.exports = config

# have to set a secret backend-only route
backendRoutes = require('../../common/config/routes.backend.coffee')
backendRoutes.hirefire =
  info: "/hirefire/#{config.HIREFIRE.API_KEY}/info"
