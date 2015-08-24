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

gulp.task 'styles', -> styles paths.map

gulp.task 'stylesWatch', gulp.series 'styles', (done) ->
  gulp.watch [
    paths.map.less
    paths.map.styles
    paths.map.stylus
  ], gulp.series 'styles'
  done()

gulp.task 'stylesAdmin', -> styles paths.admin

gulp.task 'stylesWatchAdmin', gulp.series 'stylesAdmin', (done) ->
  gulp.watch [
    paths.admin.less
    paths.admin.styles
    paths.admin.stylus
  ], gulp.series 'stylesAdmin'
  done()