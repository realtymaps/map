paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
plumber = require 'gulp-plumber'

$ = require('gulp-load-plugins')()

_testCb = null

markup = (app) ->
  _testCb() if _testCb

  gulp.src paths[app].jade
  .pipe plumber()
  .pipe $.consolidate 'jade',
    doctype: 'html'
    pretty: '  '
  .on   'error', conf.errorHandler 'Jade'
  .pipe $.minifyHtml
    empty: true
    spare: true
    quotes: true
    conditionals: true
  .pipe $.angularTemplatecache "#{app}.templates.js",
    module: paths[app].appName
    root: '.'
  .pipe gulp.dest paths.destFull.scripts
  .pipe $.size
    title: paths.dest.root
    showFiles: true

markupImpl = -> markup 'map'
markupAdminImpl = -> markup 'admin'

watchImpl = ->
  gulp.watch paths.map.jade, markupImpl

watchAdminImpl = ->
  gulp.watch paths.admin.jade, markupAdminImpl

gulp.task 'markup', markupImpl

gulp.task 'markupWatch', (done) ->
  watchImpl()
  done()

gulp.task 'markupAdmin', markupAdminImpl

gulp.task 'markupWatchAdmin', (done) ->
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
