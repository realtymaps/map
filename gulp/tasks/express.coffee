gulp = require 'gulp'
log = require('gulp-util').log
config = require '../../backend/config/config'
#server = require 'gulp-express'
nodemon = require 'gulp-nodemon'
do require '../../common/config/dbChecker.coffee'

options =
  script: "backend/server.coffee"
  ext: 'js coffee cson'
  ignore: [
    'node_modules/**'
    'bower_componets/**'
    'frontend/**'
    '_public/**'
    'mean.coffee.log'
  ]
  delay: 1
  execMap:
    coffee: 'coffee'
  verbose: false

run_express = (done, nodeArgs) ->
  log "ENV Port in gulp: " + config.PORT
  options.nodeArgs = nodeArgs if nodeArgs
  nodemon options
  done()

gulp.task "express", gulp.series 'otherAssets', (done) ->
  run_express(done)

gulp.task "express_debug", (done) ->
  run_express done, ['--debug=9999']

gulp.task "pack_express", gulp.parallel 'webpack', 'otherAssets', (done) ->
  run_express(done)
