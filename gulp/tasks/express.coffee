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
    'app/**'
    '_public/**'
    'mean.coffee.log'
  ]
  delay: 1
  execMap:
    coffee: 'coffee'
  verbose: false

run_express = (nodeArgs) ->
  log "ENV Port in gulp: " + config.PORT
  options.nodeArgs = nodeArgs if nodeArgs
  nodemon options

gulp.task "express_spec", ['spec'], ->
  run_express()

gulp.task "express", ['otherAssets'], ->
  run_express()

gulp.task "express_debug", ->
  run_express ['--debug=9999']
 