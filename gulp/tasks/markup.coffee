gulp = require 'gulp'
gutil = require 'gulp-util'
plumber = require 'gulp-plumber'
consolidate = require 'gulp-consolidate'
rename = require 'gulp-rename'
conf = require './conf'

paths = require '../../common/config/paths'

gulp.task 'markup', ->
  gulp.src(paths.rmap.jade)
  .pipe plumber()
  .pipe consolidate('jade',
    doctype: 'html'
    pretty: '  ')
    .on 'error', conf.errorHandler '[Jade]'
  .pipe rename (path) -> path.extname = '.html'
  .pipe gulp.dest paths.destFull.styles
