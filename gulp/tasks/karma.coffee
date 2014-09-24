gulp = require 'gulp'
karma = require 'gulp-karma' #forked to https://github.com/lazd/gulp-karma see below
open  = require "gulp-open"
concat = require 'gulp-concat'
log = require('gulp-util').log


gulp.task 'coverage', ["spec"],->
  gulp.src('')
  .pipe open '',
    url: "http://localhost:3000/coverage/chrome/index.html"
    app: "Google Chrome" #osx , linux: google-chrome, windows: chrome

run = (config) ->
  gulp.src("")
  .pipe karma(config)

gulp.task 'karma', ->
  log "#{realtymaps.dashes} Karma Setup #{realtymaps.dashes}"
  run(
    configFile: 'karma/karma.conf.coffee'
    action: 'run'
    # NOTICE:
    # noOverrideFiles -
    #
    # see issue https://github.com/lazd/gulp-karma/pull/18, why I forked to nmccready
    # otherwise you will need the src below in gulpspec.coffee , spec task
    noOverrideFiles: true
  ).on 'error',
    (err) -> throw err #new Error("Karma Specs failed!")
    #Make sure failed tests cause gulp to exit non-zero

# gulp.task 'karma_watch', ->
#   run
#     configFile: 'karma/karma_watch.conf.coffee'
#     action: 'watch'
#     noOverrideFiles: true

gulp.task 'frontendSpec', ['karma']

# gulp.task 'karma_watch', ['karma_no_fail'], ->
#   gulp.watch 'app/**', ['karma_no_fail']
#   gulp.watch 'spec/app/**', ['karma_no_fail']
