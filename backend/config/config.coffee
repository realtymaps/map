_ = require 'lodash'
path = require 'path'

base =
  ENV: process.env.NODE_ENV || 'development'
  ROOT_PATH: path.join(__dirname, '..')
  FRONTEND_ASSETS_PATH: path.join(__dirname, '../../_public')
  PORT: process.env.PORT || 4000
  LOGGING:
    PATH: "mean.coffee.log"
    LEVEL: 'info'
    FILE_AND_LINE: false
    LONG_STACK_TRACES: false
  USER_DB:
    client: 'pg'
    connection: process.env.DATABASE_URL
    pool:
      min: 2
      max: 10
  PROPERTY_DB:
    client: 'pg'
    connection: process.env.HEROKU_POSTGRESQL_ONYX_URL
    pool:
      min: 2
      max: 10
  SESSION:
    secret: "thisisthesecretforthesession"
    cookie: { maxAge: null, secure: true }
    unset: "destroy"
  DB_CACHE_TIMES:
    SLOW_REFRESH: 10*60*1000  # 10 minutes
    FAST_REFRESH: 60*1000     # 1 minute
  USE_NODETIME: false
  USE_ERROR_HANDLER: false
  TRUST_PROXY: 1
  DEFAULT_LANDING_URL: "/"
  LOGOUT_URL: "/"

# this one's separated out so we can re-use the USER_DB.connection value 
base.SESSION_STORE =
  conString: base.USER_DB.connection


# use environment-specific configuration as little as possible
environmentConfig =
  development:
    USER_DB:
      debug: true
    USER_DB:
      debug: true
    SESSION:
      cookie:
        secure: false
    DB_CACHE_TIMES:
      SLOW_REFRESH: 60*1000   # 1 minute
      FAST_REFRESH: 30*1000   # 30 seconds
    LOGGING:
      LEVEL: 'debug'
      FILE_AND_LINE: true
      LONG_STACK_TRACES: true
    USE_ERROR_HANDLER: true
    TRUST_PROXY: false
  staging: {}
  production:
    USE_NODETIME: true
    SESSION:
      cookie:
        secure: true


config = _.merge(base, environmentConfig[base.ENV])
#console.info "config: %j",config

module.exports = config
