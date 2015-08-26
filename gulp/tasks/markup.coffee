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

gulp.task 'markup', -> markup 'map'

gulp.task 'markupWatch', gulp.series 'markup', (done) ->
  gulp.watch paths.map.jade, gulp.series 'markup'
  done()

gulp.task 'markupAdmin', -> markup 'admin'

gulp.task 'markupWatchAdmin', gulp.series 'markupAdmin', (done) ->
  gulp.watch paths.admin.jade, gulp.series 'markupAdmin'
  done()
