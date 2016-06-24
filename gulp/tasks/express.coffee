gulp = require 'gulp'
log = require('gulp-util').log
config = require '../../backend/config/config'

nodemon = require 'gulp-nodemon'
coffeelint = require 'gulp-coffeelint'
argv = require('yargs').argv

options =
  script: 'backend/server.coffee'
  ext: 'js coffee cson'
  watch: [
    'backend'
    'common'
  ]
  delay: 1
  execMap:
    coffee: 'coffee'
  verbose: false
  # tasks: ['lint'] # THIS IS KILLING THE RESTART SPEED OF NODEMON , this should be done in a gulp watch or not at all

run_express = (done) ->
  log 'ENV Port in gulp: ' + config.PORT + ', nodemon exec: ' + options.execMap.coffee
  nodemon options
  done()

gulp.task 'lint', () ->
  gulp.src [
    'gulp/**/*.coffee'
    'backend/**/*.coffee'
    'common/**/*.coffee'
    # 'spec/**/*.coffee'
  ]
  .pipe coffeelint()
  .pipe coffeelint.reporter()

gulp.task 'express', gulp.parallel 'lint', (done) ->
  if argv.debug
    port = if argv.debug == true then 9999 else argv.debug

    log 'Start Express with debugger on port ' + port
    options.execMap.coffee += ' --nodejs --debug=' + port

  run_express(done)
