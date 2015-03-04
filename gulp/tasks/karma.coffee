gulp = require 'gulp'
karma = require('karma').server
open  = require "gulp-open"
concat = require 'gulp-concat'
log = require('gulp-util').log
plumber = require 'gulp-plumber'

karmaConf = require.resolve('../../karma/karma.conf.coffee')

karmaRunner = (done) ->
  karma_callback = (code) =>
    log "Karma Callback Code: #{code}"
    done(code)

  log "-- Karma Setup --"
  try
    karma.start
      configFile: karmaConf
      singleRun: true
    , karma_callback
  catch e
    log "KARMA ERROR: #{e}"
    done(e)


gulp.task 'karma', gulp.series 'build', (done) ->
  karmaRunner(done)

gulp.task 'karmaOnly', (done) ->
  karmaRunner(done)

gulp.task 'frontendSpec', gulp.parallel 'karma'