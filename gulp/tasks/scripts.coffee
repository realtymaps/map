paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

gulp.task 'scripts', ->
  gulp.src paths.rmap.scripts
  .pipe $.wrapCommonjs
    autoRequire: false
    pathModifier: (path) ->
      path.replace /.*?\/(frontend\/.*)/, '$1'
  .pipe $.sourcemaps.init()
  .pipe $.coffeelint()
  .pipe $.coffeelint.reporter()
  .pipe $.coffee()
  .on   'error', conf.errorHandler '[CoffeeScript]'
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.tmp.scripts
  .pipe $.size()
