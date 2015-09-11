paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
gutil = require 'gulp-util'
globby = require 'globby'
$ = require('gulp-load-plugins')()
browserify = require 'browserify'
browserify_coffeelint = require 'browserify-coffeelint'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
vinylPaths = require 'vinyl-paths'
del = require 'del'
prettyHrtime = require 'pretty-hrtime'
through = require 'through2'
conf = require './conf'
require './markup'
ignore = require 'ignore'

getScriptsGlob = (app) ->
  [paths.frontendCommon.root + 'scripts/**/*.coffee', paths[app].root + 'scripts/**/*.coffee']

###
Yes browserify can do build and watching itself. However, this is not optimal as we need building and watching seperated.
Otherwise you get duplicate actions on initial builds.
###
browserifyTask = (app) ->
  #straight from gulp , https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-with-globs.md
  # gulp expects tasks to return a stream, so we create one here.
  inputGlob = getScriptsGlob(app)
  outputName = app + '.bundle.js'
  startTime = ''

  pipeline = (stream) ->
    stream
    .on 'error', (err) ->
      conf.errorHandler 'Bundler'
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

  globby inputGlob, (err, entries) ->
    # gutil.log "entries: #{entries}"
    if (err)
      bundledStream.emit('error', err)
      return

    config =
      entries: entries
      outputName: outputName
      dest: paths.destFull.scripts
      debug: true

    # This file acts like a .gitignore for excluding files from linter
    lintIgnore = ignore().addIgnoreFile __dirname + '/../../.coffeelintignore'

    b = browserify config
      .transform (file, overrideOptions = {}) ->
        if (lintIgnore.filter [file]).length == 0
          # console.log 'Ignoring', file
          file += '.ignore'
        browserify_coffeelint file, _.extend(overrideOptions, doEmitErrors: true)
        # if process.env.CIRCLECI #enforce linting at CircleCI
        #   lintStream.on 'error', ->
        #     process.exit(1)
        # lintStream

    bundle = (stream) ->
      startTime = process.hrtime()
      gutil.log 'Bundling', gutil.colors.blue(config.outputName) + '...'
      b.bundle().pipe(stream)

    if config.require
      b.require config.require
    if config.external
      b.external config.external

    bundle bundledStream

  bundledStream

browserifyImpl = ->
  browserifyTask 'map'

browserIfyAdminImpl = ->
  browserifyTask 'admin'

gulp.task 'browserify', browserifyImpl

gulp.task 'browserifyWatch', (done) ->
  gulp.watch getScriptsGlob('map'), browserifyImpl
  done()

gulp.task 'browserifyAdmin', browserIfyAdminImpl

gulp.task 'browserifyWatchAdmin', (done) ->
  gulp.watch getScriptsGlob('admin'), browserIfyAdminImpl
  done()
