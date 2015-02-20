gulp = require 'gulp'
karma = require('karma').server
open  = require "gulp-open"
concat = require 'gulp-concat'
log = require('gulp-util').log
plumber = require 'gulp-plumber'

gulp.task 'coverage', ["spec"],->
  gulp.src('')
  .pipe plumber()
  .pipe open '',
    url: "http://localhost:3000/coverage/chrome/index.html"
    app: "Google Chrome" #osx , linux: google-chrome, windows: chrome


karmaConf = require.resolve('../../karma/karma.conf.coffee')



gulp.task 'karma', ['build'], (done) ->
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
  

gulp.task 'frontendSpec', ['karma']