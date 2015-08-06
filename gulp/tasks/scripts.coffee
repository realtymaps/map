paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

gulp.task 'scripts', ->
  gulp.src [
    paths.rmap.scripts
  ]
  .pipe coffeeFilter = $.filter '**/*.coffee', restore: true
  .pipe $.wrapCommonjs
    autoRequire: false
    pathModifier: (path) ->
      path.replace /.*?(frontend\/.*)/, '$1'
  .pipe $.sourcemaps.init()
  .pipe $.coffeelint null, require './coffeelint.coffee'
  .pipe $.coffeelint.reporter()
  .pipe $.coffee()
  .on   'error', conf.errorHandler '[CoffeeScript]'
  .pipe $.ngAnnotate()
  .pipe $.angularFilesort()
  .pipe $.sourcemaps.write()
  .pipe coffeeFilter.restore
  .pipe $.addSrc.append paths.destFull.scripts + '/templateCacheHtml.js'
  .pipe $.concat 'main.wp.js'
  .pipe $.uglify()
  .pipe gulp.dest paths.destFull.scripts
  .pipe $.size
    title: paths.dest.root
    showFiles: true
