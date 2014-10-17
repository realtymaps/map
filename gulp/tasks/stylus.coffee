gulp = require 'gulp'
log = require('gulp-util').log
path = require '../paths'
logFile = require '../debug/logFile'
plumber = require 'gulp-plumber'
stylus = require 'gulp-stylus'

gulp.task 'stylus', () ->
  gulp.src(path.stylus)
  .pipe plumber()
  .pipe(stylus())
  .on 'error', (err) ->
    log "#{err}"
  .pipe(gulp.dest path.destFull.styles)
