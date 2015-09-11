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

stylesImpl = ->
  styles paths.map

stylesAdminImpl = ->
  styles paths.admin

gulp.task 'styles', -> stylesImpl()

gulp.task 'stylesWatch', (done) ->
  gulp.watch [
    paths.map.less
    paths.map.styles
    paths.map.stylus
  ], stylesImpl
  done()

gulp.task 'stylesAdmin', stylesAdminImpl

gulp.task 'stylesWatchAdmin', (done) ->
  gulp.watch [
    paths.map.less
    paths.map.styles
    paths.map.stylus
    paths.admin.less
    paths.admin.styles
    paths.admin.stylus
  ], stylesAdminImpl
  done()
