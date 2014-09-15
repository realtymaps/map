gulp = require 'gulp'
log = require('gulp-util').log
#server = require 'gulp-express'
nodemon = require 'gulp-nodemon'

gulp.task "express", ->
  log "ENV Port in gulp: " + process.env.PORT
  nodemon(script: "backend/server.coffee")
