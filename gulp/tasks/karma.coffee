gulp = require 'gulp'
karma = require('karma').server
open  = require "gulp-open"
concat = require 'gulp-concat'
{log} = require('gulp-util')

karmaConf = require.resolve('../../karma/karma.conf.coffee')

karmaRunner = (done) ->
  log "-- Karma Setup --"
  try
    karma.start
      configFile: karmaConf
      singleRun: true
    , (code) =>
      log "Karma Callback Code: #{code}"
      done(code)
  catch e
    console.log "KARMA ERROR: #{e}"
    log "KARMA ERROR: #{e}"
    done(e)


gulp.task 'karma', (done) ->
  karmaRunner(done)

gulp.task 'karmaOnly', (done) ->
  karmaRunner(done)

gulp.task 'frontendSpec', gulp.series 'karma'
