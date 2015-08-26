paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
gutil = require 'gulp-util'
globby = require 'globby'
$ = require('gulp-load-plugins')()
browserify = require 'browserify'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
vinylPaths = require 'vinyl-paths'
del = require 'del'
prettyHrtime = require 'pretty-hrtime'
through = require 'through2'
conf = require './conf'
require './markup'

browserifyTask = (app, watch = false) ->
  #straight from gulp , https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-with-globs.md
  # gulp expects tasks to return a stream, so we create one here.
  inputGlob = paths[app].root + 'scripts/**/*.coffee'
  outputName = app + '.bundle.js'
  startTime = ''

  pipeline = (stream) ->
    stream
    .on 'error', conf.errorHandler 'Bundler'
    .pipe source outputName
    .pipe buffer()
    .pipe $.sourcemaps.init loadMaps: true
    .pipe $.sourcemaps.write()
    .pipe gulp.dest paths.destFull.scripts
    .on 'end', ->
      timestamp = prettyHrtime process.hrtime startTime
      gutil.log 'Bundled', gutil.colors.blue(outputName), 'in', gutil.colors.magenta(timestamp)
    stream

  bundledStream = pipeline through()

  globby [inputGlob], (err, entries) ->
    # gutil.log "entries: #{entries}"
    if (err)
      bundledStream.emit('error', err)
      return

    config =
      entries: entries
      outputName: outputName
      dest: paths.destFull.scripts
      debug: true

    if watch
      _.extend config, watchify.args

    b = browserify config

    bundle = (stream) ->
      startTime = process.hrtime()
      gutil.log 'Bundling', gutil.colors.blue(config.outputName) + '...'
      b.bundle().pipe(stream)

    if watch
      b = watchify b
      b.on 'update', () ->
        bundle pipeline through()
      gutil.log 'Watching files required by', gutil.colors.yellow(config.entries)
    else
      if config.require
        b.require config.require
      if config.external
        b.external config.external

    bundle bundledStream

  bundledStream

gulp.task 'browserify', -> browserifyTask 'map'

gulp.task 'browserifyWatch', -> browserifyTask 'map', true

gulp.task 'browserifyAdmin', -> browserifyTask 'admin'

gulp.task 'browserifyWatchAdmin', -> browserifyTask 'admin', true
