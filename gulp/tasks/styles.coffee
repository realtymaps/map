paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

styles = (src) ->
  gulp.src [
    src.less
    src.styles
    src.rootStylus
  ]
  .pipe $.sourcemaps.init()

  .pipe lessFilter = $.filter '**/*.less', restore: true
  .pipe $.less()
  .on   'error', conf.errorHandler 'Less'
  .pipe lessFilter.restore

  .pipe stylusFilter = $.filter '**/*.styl', restore: true
  .pipe $.stylus()
  .on   'error', conf.errorHandler 'Stylus'
  .pipe stylusFilter.restore

  .pipe $.order [
    src.less
    src.styles
    src.rootStylus
  ]
  .pipe $.concat src.name + '.css'
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: true

gulp.task 'styles', -> styles paths.rmap
gulp.task 'stylesAdmin', -> styles paths.admin
