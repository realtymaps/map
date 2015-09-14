paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

_testCb = null

styles = (src) ->
  _testCb() if _testCb

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

watchImpl = ->
  gulp.watch [
    paths.map.less
    paths.map.styles
    paths.map.stylus
  ], stylesImpl

watchAdminImpl = ->
  gulp.watch [
    paths.map.less
    paths.map.styles
    paths.map.stylus
    paths.admin.less
    paths.admin.styles
    paths.admin.stylus
  ], stylesAdminImpl

gulp.task 'styles', stylesImpl

gulp.task 'stylesWatch', (done) ->
  watchImpl()
  done()

gulp.task 'stylesAdmin', stylesAdminImpl

gulp.task 'stylesWatchAdmin', (done) ->
  watchAdminImpl()
  done()


module.exports =
  ###
  For intent and purposes these exports are for testing only
  ###
  watchImpl: watchImpl
  watchAdminImpl:watchAdminImpl
  setTestCb: (cb) ->
    _testCb = cb
