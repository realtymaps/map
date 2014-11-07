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

run = (config) ->
  gulp.src("")
  .pipe plumber()
  .pipe karma(config)

karmaConf = require.resolve('../../karma/karma.conf.coffee')
log "KarmaConf #{karmaConf}"
gulp.task 'karma', ['build'], (done) ->
  log "#{realtymaps.dashes} Karma Setup #{realtymaps.dashes}"
  karma.start
    configFile: karmaConf
    singleRun: true
    , done

# gulp.task 'karma_watch', ->
#   run
#     configFile: 'karma/karma_watch.conf.coffee'
#     action: 'watch'
#     noOverrideFiles: true

gulp.task 'frontendSpec', ['karma']

# gulp.task 'karma_watch', ['karma_no_fail'], ->
#   gulp.watch 'app/**', ['karma_no_fail']
#   gulp.watch 'spec/app/**', ['karma_no_fail']
