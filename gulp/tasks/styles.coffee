paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()


gulp.task 'styles', ->
  gulp.src [
    paths.rmap.styles
    paths.rmap.stylus
    paths.rmap.less
  ]
  .pipe $.sourcemaps.init()
  .pipe lessFilter = $.filter '**/*.less', restore: true
  .pipe $.less()
  .on   'error', conf.errorHandler '[Less]'
  .pipe lessFilter.restore
  .pipe stylusFilter = $.filter '**/*.styl', restore: true
  .pipe $.stylus()
  .on   'error', conf.errorHandler '[Stylus]'
  .pipe stylusFilter.restore
  .pipe $.sourcemaps.write()
  .pipe $.concat 'main.wp.css'
  # .pipe $.minifyCss()
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: true
