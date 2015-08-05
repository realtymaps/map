gulp = require 'gulp'
gutil = require 'gulp-util'
path = require 'path'
$ = require('gulp-load-plugins')()

paths = require '../../common/config/paths'

gulp.task 'stylus', ->
  gulp.src paths.rmap.stylus
  .pipe $.sourcemaps.init()
  .pipe $.stylus()
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.tmp.styles

gulp.task 'less', ->
  gulp.src paths.rmap.less
  .pipe $.sourcemaps.init()
  .pipe $.less()
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.tmp.styles

gulp.task 'styles', gulp.series 'stylus', 'less'
