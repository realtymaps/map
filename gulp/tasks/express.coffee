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
    'dist/**/**'
  ]
  delay: 1

gulp.task "express", ->
  log "ENV Port in gulp: " + config.PORT
  nodemon options

gulp.task "express_debug", ->
  log "ENV Port in gulp: " + config.PORT
  options.nodeArgs = ['--debug=9999']
  nodemon options
