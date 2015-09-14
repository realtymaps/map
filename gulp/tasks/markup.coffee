paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
plumber = require 'gulp-plumber'

$ = require('gulp-load-plugins')()

markup = (app) ->
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

gulp.task 'markup', markupImpl

gulp.task 'markupWatch', (done) ->
  gulp.watch paths.map.jade
  markupImpl()
  done()

gulp.task 'markupAdmin', markupAdminImpl

gulp.task 'markupWatchAdmin', (done) ->
  gulp.watch paths.admin.jade
  markupAdminImpl()
  done()
