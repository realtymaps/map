gulp = require 'gulp'
log = require('gulp-util').log
config = require '../../backend/config/config'
#server = require 'gulp-express'
nodemon = require 'gulp-nodemon'
do require '../../common/config/dbChecker.coffee'
coffeelint = require 'gulp-coffeelint'

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

run_express = (done, nodeArgs) ->
  log 'ENV Port in gulp: ' + config.PORT
  options.nodeArgs = nodeArgs if nodeArgs
  nodemon options
  done()

gulp.task 'lint', () ->
  gulp.src [
    'gulp/**/*.coffee'
    'backend/**/*.coffee'
    'common/**/*.coffee'
    # 'spec/**/*.coffee'
    '!common/documentTemplates/**'
  ]
  .pipe coffeelint()
  .pipe coffeelint.reporter()

gulp.task 'express', gulp.parallel 'lint', (done) ->
  run_express(done)

gulp.task 'express_debug', gulp.parallel 'lint', (done) ->
  run_express done, ['--debug=9999']
