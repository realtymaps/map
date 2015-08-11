paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

browserify = require('browserify')
source = require('vinyl-source-stream')

gulp.task 'browserify', ->
  browserify paths.rmap.root + '/scripts/app.coffee'
  .bundle()
  .pipe source 'main.wp.js'
  .pipe gulp.dest paths.destFull.scripts

gulp.task 'coffee', ->
  gulp.src [
    paths.rmap.scripts
  ]
  .pipe coffeeFilter = $.filter '**/*.coffee', restore: true
  .pipe $.sourcemaps.init()
  .pipe $.coffeelint null, require './coffeelint.coffee'
  .pipe $.coffeelint.reporter()
  .pipe $.coffee()
  .on   'error', conf.errorHandler '[CoffeeScript]'
  .pipe $.ngAnnotate()
  .pipe $.sourcemaps.write()
  .pipe coffeeFilter.restore
  .pipe $.addSrc.append paths.destFull.scripts + '/templateCacheHtml.js'
  .pipe $.concat 'main.wp.js'
  .pipe $.uglify()
  .pipe gulp.dest paths.destFull.scripts
  .pipe $.size
    title: paths.dest.root
    showFiles: true

gulp.task 'scripts', gulp.series 'browserify', ->
