base =
  ENV: process.env.NODE_ENV || 'development'
  PORT: process.env.PORT || 4000
  LOGPATH: "mean.coffee.log"
  COOKIE_SECRET: "thisisthesecretforthesession"
  DBURLTEST: "mongodb://localhost/meandb_test"
  USER_DB_CONFIG:
    client: 'pg'
    connection: process.env.DATABASE_URL
    pool:
      min: 2
      max: 10
  PROPERTY_DB_CONFIG:
    client: 'pg'
    connection: process.env.HEROKU_POSTGRESQL_ONYX_URL
    pool:
      min: 2
      max: 10

# we should use environment-specific configuration as little as possible
dev = {}
prod = {}



mergeConfig = (config) ->
  for key, val of config
    base[key] = val
  base

module.exports = do ->
  switch base.ENV
    when 'development' then return mergeConfig(dev)
    when 'production' then return mergeConfig(prod)
    else return mergeConfig(dev)
