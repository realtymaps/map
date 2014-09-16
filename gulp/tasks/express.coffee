gulp = require 'gulp'
log = require('gulp-util').log
#server = require 'gulp-express'
nodemon = require 'gulp-nodemon'
require('../../common/config/dbChecker.coffee')()

gulp.task "express", ->
  log "ENV Port in gulp: " + process.env.PORT
  nodemon
    script: "backend/server.coffee"
    ext: 'js coffee cson'
    ignore: ['node_modules/**','bower_componets/**', 'app/**', 'dist/**/**']
    delay: 1
