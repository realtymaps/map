gulp = require 'gulp'
log = require('gulp-util').log
size = require 'gulp-size'
path = require '../paths'
inject = require 'gulp-inject'
es = require 'event-stream'
logFile = require '../debug/logFile'
jade = require 'gulp-jade'
plumber = require 'gulp-plumber'
clean = require 'gulp-rimraf'

toInject = [
  path.dest.scripts + '/vendor.js'
  path.dest.styles + '/vendor.css'
  # path.dest.fonts + '/**/*' #loaded in bootstrap itself as should most css
].map (f) -> path.dest.root + f

# log 'toInject: ' + toInject

gulp.task 'html', ['jadeTemplates'], () ->
  gulp.src(path.html)
  .pipe plumber()
#  .pipe(logFile(es))
  .pipe(inject(gulp.src(toInject, read: false), relative: true))
  .pipe(size())
  .pipe(gulp.dest '_public')

gulp.task 'jadeTemplates', () ->
  gulp.src(path.jade)
  .pipe plumber()
  .pipe jade pretty: true
  .on 'error', (err) ->
    log "#{err}"
  .pipe(gulp.dest '_public')
