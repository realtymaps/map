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
  .pipe $.angularTemplatecache 'templateCacheHtml.js',
    module: 'rmapsapp'
    root: '.'
  .pipe gulp.dest paths.destFull.scripts
