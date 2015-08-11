paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

gulp.task 'markup', ->
  gulp.src paths.rmap.jade
  .pipe $.consolidate 'jade',
    doctype: 'html'
    pretty: '  '
  .on   'error', conf.errorHandler '[Jade]'
  .pipe $.minifyHtml
    empty: true
    spare: true
    quotes: true
    conditionals: true
  .pipe $.angularTemplatecache 'map.templates.js',
    module: 'rmapsapp'
    root: '.'
  .pipe gulp.dest paths.destFull.scripts

gulp.task 'markupAdmin', ->
  gulp.src paths.admin.jade
  .pipe $.consolidate 'jade',
    doctype: 'html'
    pretty: '  '
  .on   'error', conf.errorHandler '[Jade]'
  .pipe $.minifyHtml
    empty: true
    spare: true
    quotes: true
    conditionals: true
  .pipe $.angularTemplatecache 'admin.templates.js',
    module: 'rmapsadminapp'
    root: '.'
  .pipe gulp.dest paths.destFull.scripts
