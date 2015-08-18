paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
gutil = require 'gulp-util'
$ = require('gulp-load-plugins')()
browserify = require 'browserify'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
vinylPaths = require 'vinyl-paths'
del = require 'del'
prettyHrtime = require 'pretty-hrtime'
conf = require './conf'
require './markup'

browserifyTask = (app, watch = false) ->
  config =
    entries: paths[app].root + 'scripts/app.coffee'
    outputName: app + '.bundle.js'
    dest: paths.destFull.scripts
    debug: true

  if watch
    _.extend config, watchify.args

  b = browserify config
  startTime = ''

  bundle = () ->
    startTime = process.hrtime()
    gutil.log 'Bundling', gutil.colors.blue(config.outputName) + '...'
    b.bundle()
    .on 'error', conf.errorHandler 'Bundler'
    .pipe source config.outputName
    .pipe buffer()
    .pipe $.sourcemaps.init loadMaps: true
    .pipe $.sourcemaps.write()
    .pipe gulp.dest paths.destFull.scripts
    .on 'end', ->
      timestamp = prettyHrtime process.hrtime startTime
      gutil.log 'Bundled', gutil.colors.blue(config.outputName), 'in', gutil.colors.magenta(timestamp)

  if watch
    b = watchify b
    b.on 'update', bundle
    gutil.log 'Watching files required by', gutil.colors.yellow(config.entries)
  else
    if config.require
      b.require config.require
    if config.external
      b.external config.external

  bundle()

gulp.task 'browserify', -> browserifyTask 'map'

gulp.task 'browserifyWatch', -> browserifyTask 'map', true

gulp.task 'browserifyAdmin', -> browserifyTask 'admin'

gulp.task 'browserifyWatchAdmin', -> browserifyTask 'admin', true
