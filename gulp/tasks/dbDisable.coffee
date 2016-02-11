gulp = require 'gulp'

gulp.task 'overrideDbCreds', (done) ->
  process.env.MAIN_DATABASE_URL_ORIG ?= process.env.MAIN_DATABASE_URL
  process.env.RAW_TEMP_DATABASE_URL_ORIG ?= process.env.RAW_TEMP_DATABASE_URL
  process.env.MAIN_DATABASE_URL = 'postgres://bad:creds@localhost:5432/dummy_db_name'
  process.env.RAW_TEMP_DATABASE_URL = 'postgres://bad:creds@localhost:5432/dummy_db_name'
  done()

gulp.task 'fixDbCreds', (done) ->
  process.env.MAIN_DATABASE_URL = process.env.MAIN_DATABASE_URL_ORIG
  process.env.RAW_TEMP_DATABASE_URL = process.env.RAW_TEMP_DATABASE_URL_ORIG
  done()
