gulp = require 'gulp'
log = require('gulp').log
#server = require 'gulp-express'
shell = require 'gulp-shell'
nodemon = require 'gulp-nodemon'

# gulp.task "express", shell.task ['coffee server.coffee']
gulp.task "express", ->
  log "ENV Port in gulp: " + process.env.PORT
  nodemon(script: "backend/server.coffee")
