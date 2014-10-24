path = require '../paths'
gulp = require 'gulp'
uglify = require 'gulp-uglify'
coffee = require 'gulp-coffee'
plumber = require 'gulp-plumber'
sourcemaps = require 'gulp-sourcemaps'
log = require('gulp-util').log
size = require 'gulp-size'
concat = require 'gulp-concat'
log = require('gulp-util').log

gulp.task 'ugly', ['webpack'], () ->
  gulp.src("#{path.destFull.scripts}/*.js")
  .pipe plumber()
  .pipe(uglify())
  .on 'error', log
  .pipe(gulp.dest path.destFull.scripts)
