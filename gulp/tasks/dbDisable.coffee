gulp = require 'gulp'
dbs = require '../../backend/config/dbs'

gulp.task 'disableDbs', (done) ->
  dbs.disable('unit tests')
  done()

gulp.task 'enableDbs', (done) ->
  dbs.enable()
  done()
